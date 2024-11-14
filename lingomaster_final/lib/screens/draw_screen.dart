import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingomaster_final/service/database.dart';
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
    penStrokeWidth: 10,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  File? selectedMedia;
  double _opacity = 0.3;
  bool _showTrace = false;
  bool _isPracticeMode = false;

  // Get the local storage directory path
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

  // determine level from collection name
  int _getLevelFromCollection() {
    switch (widget.collectionName) {
      case 'characters':
        return 1;
      case 'words':
        return 2;
      case 'phrases':
        return 3;
      default:
        return 1; // Default to level 1 if collection name doesn't match
    }
  }

  // Process image before text recognition
  Future<File> _processImage(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) return inputFile;

    // Resize image if needed
    if (image.width < 200 || image.height < 200) {
      image = img.copyResize(image, width: 400, height: 400);
    } else if (image.width > 1000 || image.height > 1000) {
      image = img.copyResize(image, width: 800, height: 800);
    }

    // Save to local storage instead of temp directory
    final path = await _localPath;
    final processedFile = File('$path/processed_image.png');
    await processedFile.writeAsBytes(img.encodePng(image));

    return processedFile;
  }

  Future<double> _calculateScore(String? extractedText) {
    if (extractedText == null || extractedText.isEmpty)
      return Future.value(0.0);

    // Convert both strings to the same case and remove whitespace
    String normalizedExtracted = extractedText.trim().toLowerCase();
    String normalizedTarget = widget.targetHiragana.trim().toLowerCase();

    // Direct match
    if (normalizedExtracted.contains(normalizedTarget)) {
      return Future.value(100.0);
    }

    // Check if the target character appears in any form
    // This helps with slight variations in recognition
    List<String> variations = [
      normalizedTarget,
      // Add common variations or misrecognitions of hiragana characters
      // This can be expanded based on observed patterns
    ];

    for (String variation in variations) {
      if (normalizedExtracted.contains(variation)) {
        return Future.value(80.0); // High score for variation matches
      }
    }

    // Calculate partial matches
    // If the recognized text contains some similar characters
    // This threshold can be adjusted based on your needs
    return Future.value(40.0);
  }

  Future<String?> _extractText(File file) async {
    try {
      // Process the image first
      File processedFile = await _processImage(file);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.japanese,
      );

      final InputImage inputImage = InputImage.fromFile(processedFile);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close();

      // Combine all recognized text blocks
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
        double score = await _calculateScore(extractedText);
        bool passed = score >= 40.0;

        int level = _getLevelFromCollection();

        if (passed) {
          // Modified to use new database method with level and type
          await _databaseMethods.addCompletedQuestion(
            widget.questionId,
            level,
            'written'
          );
          
          int randomBonus = _random.nextInt(10) + 1;
          int baseExp = _isPracticeMode ? 10 : 20;
          int totalExp = baseExp + randomBonus;
          await _databaseMethods.modifyUserExp(totalExp);
        } else {
          if (!_isPracticeMode) {
            await _databaseMethods.modifyUserHearts(-1);
          }
        }

        if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Your Score"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Score: ${score.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
              Text(
                passed ? "Good job!" : "Keep Practicing!",
                style: TextStyle(
                  fontSize: 18,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
              if (passed) ...[
                const SizedBox(height: 10),
                const Text(
                  "XP Added!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ] else if (!_isPracticeMode) ...[
                const SizedBox(height: 10),
                const Text(
                  "Lost 1 Heart",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
              if (extractedText != null && extractedText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "Recognized text: $extractedText",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 20),
              const Text("Your Drawing:"),
              SizedBox(
                height: 100,
                width: 100,
                child: Image.file(localFile),
              ),
              const SizedBox(height: 10),
              Text(
                "Target Character: ${widget.targetHiragana}",
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Try Again"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Continue"),
            ),
          ],
        ),
      );
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

        // Check if the uploaded image contains the correct character
        String? extractedText = await _extractText(selectedMedia!);
        if (extractedText != null &&
            extractedText.contains(widget.targetHiragana)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Success!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Character recognized successfully!"),
                  const SizedBox(height: 10),
                  Image.file(selectedMedia!, height: 100),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Continue"),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Try Again"),
              content:
                  const Text("Character not recognized. Please try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
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
        fit: BoxFit.scaleDown, // Ensures the text scales down to fit
        child: Text(
          widget.targetHiragana,
          style: TextStyle(
            fontSize: 200, // Maximum font size, will scale down as needed
            color: Colors.grey.withOpacity(_opacity),
            fontFamily: 'NotoSansJP', // Ensure this font is included in pubspec.yaml
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
            Text('• No hearts will be lost on failure'),
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
