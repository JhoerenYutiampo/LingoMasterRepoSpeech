import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  _AddQuestionPageState createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _hiraganaController = TextEditingController();
  PlatformFile? _audioFile;
  PlatformFile? _imageFile;
  String? _selectedCollection;

  final List<String> _collections = ['characters', 'words', 'phrases'];

  // Function to pick an audio file
  Future<void> _pickAudioFile() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _audioFile = result.files.first;
      });
    }
  }

  // Function to pick an image file
  Future<void> _pickImageFile() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageFile = result.files.first;
      });
    }
  }

  // Upload file to Firebase Storage and return download URL
  Future<String> _uploadFileToStorage(PlatformFile file, String folder) async {
    // Create a reference to Firebase Storage
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('$folder/${file.name}'); // Store in specified folder

    // Upload the file
    UploadTask uploadTask = storageReference.putFile(File(file.path!));
    TaskSnapshot taskSnapshot = await uploadTask;

    // Get the download URL
    String downloadURL = await taskSnapshot.ref.getDownloadURL();
    return downloadURL;
  }

  // Function to handle saving the question to Firebase
  Future<void> _saveQuestion() async {
    if (_selectedCollection != null &&
        _englishController.text.isNotEmpty &&
        _hiraganaController.text.isNotEmpty &&
        _audioFile != null &&
        _imageFile != null) {
      // Upload audio file to Firebase Storage and get URL
      String audioURL = await _uploadFileToStorage(_audioFile!, 'audio_files');

      // Upload image file to Firebase Storage and get URL
      String imageURL = await _uploadFileToStorage(_imageFile!, 'image_files');

      // Add the question data to Firestore, including the file URLs
      await FirebaseFirestore.instance.collection(_selectedCollection!).add({
        'english': _englishController.text,
        'hiragana': _hiraganaController.text,
        'audio': audioURL, // Save the audio URL
        'image': imageURL, // Save the image URL
      });

      // Clear fields after saving
      _englishController.clear();
      _hiraganaController.clear();
      setState(() {
        _audioFile = null;
        _imageFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Question"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for static collection selection
            DropdownButtonFormField<String>(
              value: _selectedCollection,
              items: _collections
                  .map((collection) => DropdownMenuItem(
                        value: collection,
                        child: Text(collection),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollection = value;
                });
              },
              decoration: const InputDecoration(
                labelText: "Select Collection",
              ),
            ),
            const SizedBox(height: 20),

            // English input field
            TextField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: "English",
              ),
            ),
            const SizedBox(height: 20),

            // Hiragana input field
            TextField(
              controller: _hiraganaController,
              decoration: const InputDecoration(
                labelText: "Hiragana",
              ),
            ),
            const SizedBox(height: 20),

            // Pick Audio file button
            ElevatedButton.icon(
              onPressed: _pickAudioFile,
              icon: const Icon(Icons.audiotrack),
              label: Text(_audioFile != null ? "Audio Selected" : "Pick Audio"),
            ),
            const SizedBox(height: 20),

            // Pick Image file button
            ElevatedButton.icon(
              onPressed: _pickImageFile,
              icon: const Icon(Icons.image),
              label: Text(_imageFile != null ? "Image Selected" : "Pick Image"),
            ),
            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _saveQuestion,
              child: const Text("Save Question"),
            ),
          ],
        ),
      ),
    );
  }
}

