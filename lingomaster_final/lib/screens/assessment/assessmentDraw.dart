import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AssessmentDraw extends StatefulWidget {
  final String targetHiragana;

  const AssessmentDraw({
    super.key,
    required this.targetHiragana,
  });

  @override
  _AssessmentDrawState createState() => _AssessmentDrawState();
}

class _AssessmentDrawState extends State<AssessmentDraw> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 15,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  File? selectedMedia;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.mediaLibrary,
    ].request();

    if (!statuses.values.every((status) => status.isGranted)) {
      print("Not all permissions are granted");
    }
  }

  Future<File> _processImage(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) return inputFile;

    if (image.width < 200 || image.height < 200) {
      image = img.copyResize(image, width: 400, height: 400);
    } else if (image.width > 1000 || image.height > 1000) {
      image = img.copyResize(image, width: 800, height: 800);
    }

    final path = await _localPath;
    final processedFile = File('$path/processed_image.png');
    await processedFile.writeAsBytes(img.encodePng(image));

    return processedFile;
  }

  Future<String?> _extractText(File file) async {
    try {
      File processedFile = await _processImage(file);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.japanese,
      );

      final InputImage inputImage = InputImage.fromFile(processedFile);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close();

      String allText = recognizedText.blocks
          .map((block) => block.text.trim())
          .join(' ')
          .trim();

      return allText;
    } catch (e) {
      print("Error extracting text: $e");
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (_controller.isNotEmpty) {
      final drawnImage = await _controller.toImage();
      if (drawnImage == null) return;

      final bytes = await drawnImage.toByteData(format: ImageByteFormat.png);
      if (bytes == null) return;

      final path = await _localPath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final localFile = File('$path/drawn_image_$timestamp.png');

      try {
        await localFile.writeAsBytes(bytes.buffer.asUint8List());
        String? extractedText = await _extractText(localFile);
        bool passed = extractedText == widget.targetHiragana;

        if (passed) {
          _showSuccessDialog(localFile);
        } else {
          _showFailureDialog(localFile);
        }

        if (!mounted) return;
      } catch (e) {
        print('Error saving or processing image: $e');
        _showFailureDialog(localFile);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      List<MediaFile>? media = await GalleryPicker.pickMedia(
        context: context,
        singleMedia: true,
      );

      if (media != null && media.isNotEmpty) {
        var file = await media.first.getFile();
        setState(() {
          selectedMedia = file;
        });

        String? extractedText = await _extractText(selectedMedia!);
        if (extractedText != null && extractedText == widget.targetHiragana) {
          _showSuccessDialog(selectedMedia!);
        } else {
          _showFailureDialog(selectedMedia!);
        }
      }
    } catch (e) {
      print("Error picking media: $e");
      _showFailureDialog(File(""));
    }
  }

  void _clearDrawing() {
    _controller.clear();
  }

  void _undoDrawing() {
    _controller.undo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCameraPermissionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gallery Access'),
          content: const Text(
            'This app needs access to your gallery to upload images. Would you like to proceed?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage();
              },
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Leave Assessment?"),
        content: const Text("If you leave now, you will receive a score of 0 for this question."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context, 0); // Return 0 when user confirms exit
            },
            child: const Text("Leave"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(File image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Success!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Character recognized successfully!"),
            const SizedBox(height: 10),
            Image.file(image, height: 100),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, 1); // Return 1 for success
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(File image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Incorrect"),
        content: const Text("Character not recognized correctly."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, 0); // Return 0 for failure
            },
            child: const Text("Continue"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Trace: ${widget.targetHiragana}"),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmationDialog,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(15),
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black12, width: 2),
                  ),
                  child: Signature(
                    controller: _controller,
                    width: 300,
                    height: 300,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _undoDrawing,
                      child: const Text("Undo"),
                    ),
                    ElevatedButton(
                      onPressed: _clearDrawing,
                      child: const Text("Clear"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showCameraPermissionDialog,
                backgroundColor: Colors.purple,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}