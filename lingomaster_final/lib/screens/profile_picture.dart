import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePicture extends StatefulWidget {
  const ProfilePicture({super.key});

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uint8List? pickedImage;

  @override
  void initState() {
    super.initState();
    getProfilePicture();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTapped,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          image: pickedImage != null
              ? DecorationImage(
                  fit: BoxFit.cover,
                  image: MemoryImage(pickedImage!),
                )
              : null,
        ),
        child: pickedImage == null
            ? const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black38,
                  size: 35,
                ),
              )
            : null,
      ),
    );
  }

  Future<void> onProfileTapped() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("fLi4bw96FzL0AzUr21fOwD8RJrs2.jpg");
    final imageBytes = await image.readAsBytes();
    await imageRef.putData(imageBytes);

    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('fLi4bw96FzL0AzUr21fOwD8RJrs2.jpg');

    try {
      final imageBytes = await imageRef.getData();
      if (imageBytes == null) return;
      setState(() => pickedImage = imageBytes);
    } catch (e) {
      print('Profile picture could not be found');
    }
  }
}
