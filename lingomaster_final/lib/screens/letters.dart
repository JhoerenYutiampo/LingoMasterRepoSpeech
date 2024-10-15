import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Letters extends StatefulWidget {
  const Letters({super.key});

  @override
  State<Letters> createState() => _LettersState();
}

class _LettersState extends State<Letters> {
  File? selectedMedia;
  String? selectedHiragana;
  Map<String, bool> correctnessMap = {};

  final List<String> hiraganaChars = [
    'あ',
    'い',
    'う',
    'え',
    'お',
    'か',
    'き',
    'く',
    'け',
    'こ',
    'さ',
    'し',
    'す',
    'せ',
    'そ',
    'た',
    'ち',
    'つ',
    'て',
    'と',
    'な',
    'に',
    'ぬ',
    'ね',
    'の',
    'は',
    'ひ',
    'ふ',
    'へ',
    'ほ',
    'ま',
    'み',
    'む',
    'め',
    'も',
    'や',
    'ゆ',
    'よ',
    'ら',
    'り',
    'る',
    'れ',
    'ろ',
    'わ',
    'を',
    'ん',
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _resetCorrectnessMap(); // Reset the map on app start
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.mediaLibrary,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print("Not all permissions are granted");
    }
  }

  Future<void> _resetCorrectnessMap() async {
    // Initialize correctness map with false
    for (var char in hiraganaChars) {
      correctnessMap[char] = false;
    }
    await _saveCorrectnessMap();
  }

  Future<void> _loadCorrectnessMap() async {
    final prefs = await SharedPreferences.getInstance();
    final correctnessMapString = prefs.getString('correctnessMap');
    if (correctnessMapString != null) {
      setState(() {
        correctnessMap =
            Map<String, bool>.from(jsonDecode(correctnessMapString));
      });
    }
  }

  Future<void> _saveCorrectnessMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('correctnessMap', jsonEncode(correctnessMap));
  }

  void _selectHiragana(String char) {
    setState(() {
      selectedHiragana = char;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition"),
      ),
      body: _buildUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            print("Attempting to pick media...");
            List<MediaFile>? media = await GalleryPicker.pickMedia(
              context: context,
              singleMedia: true,
            );
            print("Media selected: $media");
            if (media != null && media.isNotEmpty) {
              var data = await media.first.getFile();
              print("Media file data: $data");
              setState(() {
                selectedMedia = data;
                print("Media file selected: ${selectedMedia!.path}");
              });
              _checkCorrectness();
                        } else {
              print("No media selected");
            }
          } catch (e) {
            print("Error picking media: $e");
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _hiraganaGridView(),
        _imageView(),
        _extractTextView(),
      ],
    );
  }

  Widget _hiraganaGridView() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.5,
        ),
        itemCount: hiraganaChars.length,
        itemBuilder: (context, index) {
          String char = hiraganaChars[index];
          return GestureDetector(
            onTap: () => _selectHiragana(char),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: correctnessMap[char] ?? false
                      ? Colors.green
                      : (selectedHiragana == char ? Colors.blue : Colors.black),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  char,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imageView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("Pick an Image for text recognition"),
      );
    }
    return Center(
      child: Image.file(
        selectedMedia!,
        width: 200,
      ),
    );
  }

  Widget _extractTextView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("No Result"),
      );
    }
    return FutureBuilder<String?>(
      future: _extractText(selectedMedia!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(fontSize: 25),
          );
        } else {
          String? recognizedText = snapshot.data;
          return Text(
            recognizedText ?? "",
            style: const TextStyle(fontSize: 25),
          );
        }
      },
    );
  }

  Future<void> _checkCorrectness() async {
    if (selectedMedia == null || selectedHiragana == null) return;

    String? extractedText = await _extractText(selectedMedia!);
    if (extractedText != null && extractedText.contains(selectedHiragana!)) {
      setState(() {
        correctnessMap[selectedHiragana!] = true;
      });
      _saveCorrectnessMap();
    }
  }

  Future<String?> _extractText(File file) async {
    try {
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.japanese,
      );
      final InputImage inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String text = recognizedText.text;
      textRecognizer.close();
      return text;
    } catch (e) {
      print("Error extracting text: $e");
      return "Error extracting text";
    }
  }
}
