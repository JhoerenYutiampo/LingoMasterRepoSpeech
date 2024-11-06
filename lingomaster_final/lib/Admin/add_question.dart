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
  final TextEditingController _pronunciationController = TextEditingController();
  PlatformFile? _audioFile;
  PlatformFile? _imageFile;
  String? _selectedCollection;

  final List<String> _collections = ['characters', 'words', 'phrases'];

  Future<void> _pickAudioFile() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioFile = result.files.first;
      });
    }
  }

  Future<void> _pickImageFile() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageFile = result.files.first;
      });
    }
  }

  Future<String> _uploadFileToStorage(PlatformFile file, String folder) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('$folder/${file.name}');
    UploadTask uploadTask = storageReference.putFile(File(file.path!));
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadURL = await taskSnapshot.ref.getDownloadURL();
    return downloadURL;
  }

  Future<void> _saveQuestion() async {
    if (_selectedCollection != null &&
        _englishController.text.isNotEmpty &&
        _hiraganaController.text.isNotEmpty &&
        _pronunciationController.text.isNotEmpty &&
        _audioFile != null &&
        _imageFile != null) {
      String audioURL = await _uploadFileToStorage(_audioFile!, 'audio_files');
      String imageURL = await _uploadFileToStorage(_imageFile!, 'image_files');

      await FirebaseFirestore.instance.collection(_selectedCollection!).add({
        'english': _englishController.text,
        'hiragana': _hiraganaController.text,
        'pronunciation': _pronunciationController.text,
        'audio': audioURL,
        'image': imageURL,
      });

      _englishController.clear();
      _hiraganaController.clear();
      _pronunciationController.clear();
      setState(() {
        _audioFile = null;
        _imageFile = null;
      });
    }
  }

  Widget _buildQuestionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(_selectedCollection ?? 'default')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.data == null || snapshot.data?.docs.isEmpty == true) {
          return const Text('No questions found');
        }

        return ListView.builder(
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            return ListTile(
              title: Text(document['english']),
              subtitle: Text(document['hiragana']),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditDialog(document);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(DocumentSnapshot document) async {
    _englishController.text = document['english'];
    _hiraganaController.text = document['hiragana'];
    _pronunciationController.text = document['pronunciation'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Question"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: "English",
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _hiraganaController,
                decoration: const InputDecoration(
                  labelText: "Hiragana",
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pronunciationController,
                decoration: const InputDecoration(
                  labelText: "Pronunciation",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await document.reference.update({
                  'english': _englishController.text,
                  'hiragana': _hiraganaController.text,
                  'pronunciation': _pronunciationController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
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
        title: const Text("Question Management"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            TextField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: "English",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hiraganaController,
              decoration: const InputDecoration(
                labelText: "Hiragana",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pronunciationController,
              decoration: const InputDecoration(
                labelText: "Pronunciation",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickAudioFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _audioFile != null ? Colors.green : null,
                  ),
                  child: const Icon(Icons.audiotrack),
                ),
                ElevatedButton(
                  onPressed: _pickImageFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _imageFile != null ? Colors.green : null,
                  ),
                  child: const Icon(Icons.image),
                ),
                ElevatedButton(
                  onPressed: _saveQuestion,
                  child: const Text("Save"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildQuestionList(),
            ),
          ],
        ),
      ),
    );
  }
}