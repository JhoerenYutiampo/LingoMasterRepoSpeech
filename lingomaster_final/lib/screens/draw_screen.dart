import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';
import 'package:signature/signature.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DrawScreen extends StatefulWidget {
  final String targetHiragana;
  final String questionId;
  final String collectionName;

  const DrawScreen({
    super.key,
    required this.targetHiragana,
    required this.questionId,
    required this.collectionName,
  });

  @override
  _DrawScreenState createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final Random _random = Random();

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 15,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  File? selectedMedia;
  double _opacity = 0.3;
  bool _showTrace = false;
  bool _isPracticeMode = false;

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

  int _getLevelFromCollection() {
    switch (widget.collectionName) {
      case 'characters':
        return 1;
      case 'words':
        return 2;
      case 'phrases':
        return 3;
      default:
        return 1;
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

        int level = _getLevelFromCollection();

        if (passed) {
          await _databaseMethods.addCompletedQuestion(
            widget.questionId,
            level,
            'written',
          );

          int randomBonus = _random.nextInt(10) + 1;
          int baseExp = _isPracticeMode ? 10 : 20;
          int totalExp = baseExp + randomBonus;
          await _databaseMethods.modifyUserExp(totalExp);

          _showSuccessDialog(localFile, passed);
        } else {
          if (!_isPracticeMode) {
            //await _databaseMethods.modifyUserHearts(-1);
          }
          _showFailureDialog(localFile, passed);
        }

        if (!mounted) return;
      } catch (e) {
        print('Error saving or processing image: $e');
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
          int level = _getLevelFromCollection();
          await _databaseMethods.addCompletedQuestion(
            widget.questionId,
            level,
            'written'
          );

          int randomBonus = _random.nextInt(10) + 1;
          int baseExp = _isPracticeMode ? 10 : 20;
          int totalExp = baseExp + randomBonus;
          await _databaseMethods.modifyUserExp(totalExp);

          _showSuccessDialog(selectedMedia!, true);
        } else {
          _showFailureDialog(selectedMedia!, false);
        }
      }
    } catch (e) {
      print("Error picking media: $e");
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

  Widget _buildTracingTemplate() {
    return Positioned.fill(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.targetHiragana,
            style: TextStyle(
              fontSize: 200,
              color: Colors.grey.withOpacity(_opacity),
              fontFamily: 'NotoSansJP',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpacityControls() {
    return Slider(
      value: _opacity,
      min: 0.1,
      max: 0.5,
      divisions: 4,
      label: 'Opacity',
      onChanged: (value) {
        setState(() {
          _opacity = value;
        });
      },
    );
  }

  Future<void> _showPracticeModeDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Practice Mode'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Practice mode will be enabled:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• Earn less XP for correct answers'),
              Text('• Template tracing will be enabled'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showTrace = true;
                  _isPracticeMode = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCameraPermissionDialog() async {
    return showDialog(
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

  void _showSuccessDialog(File image, bool passed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Character recognized successfully!"),
            const SizedBox(height: 10),
            Image.file(image, height: 100),
            const Text("Gained XP"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(File image, bool passed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Try Again"),
        content: const Text("Character not recognized. Please try again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trace: ${widget.targetHiragana}"),
        backgroundColor: Colors.purple,
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
                child: Stack(
                  children: [
                    if (_showTrace) _buildTracingTemplate(),
                    Signature(
                      controller: _controller,
                      width: 300,
                      height: 300,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
              if (!_showTrace) ...[
                ElevatedButton(
                  onPressed: _showPracticeModeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "Practice",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_showTrace) ...[
                const Text(
                  "Adjust opacity:",
                  style: TextStyle(fontSize: 16),
                ),
                _buildOpacityControls(),
              ],
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
    );
  }
}