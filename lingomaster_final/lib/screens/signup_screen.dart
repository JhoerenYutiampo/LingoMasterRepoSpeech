import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:lingomaster_final/reusable__widgets/reusable%20widget.dart';
import 'package:lingomaster_final/screens/signin_screen.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  _SignUpScreen createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final TextEditingController _userNameTextContoller = TextEditingController();
  final TextEditingController _emailTextContoller = TextEditingController();
  final TextEditingController _passwordTextContoller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "SignUp",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            hexStringToColor("CB2B93"),
            hexStringToColor("5E6148"),
            hexStringToColor("9546C4")
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter UserName", Icons.person_outline, false,
                    _userNameTextContoller),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Email", Icons.person_outline, false,
                    _emailTextContoller),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Password", Icons.lock_outline, false,
                    _passwordTextContoller),
                const SizedBox(
                  height: 20,
                ),
                SignInSignUpButton(context, false, () {
                  FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                          email: _emailTextContoller.text,
                          password: _passwordTextContoller.text)
                      .then((value) {
                    // Save username, email, and initial exp to Firestore
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(value.user?.uid) // Use the user UID
                        .set({
                          'username': _userNameTextContoller.text,
                          'email': _emailTextContoller.text,
                          'exp': 0, // Initialize exp to 0
                          'hearts': 0, // Initialize hearts to 0
                          'isAdmin': false, // Initialize isAdmin to false
                          'currentLevel': 0, // Initialize currentLevel to 0
                          'onBoarded': false, // false for first time creating the account
                          'lvl1ProgVoice': [], // Initialize lvl1ProgVoice as an empty array
                          'lvl1ProgWritten': [], // Initialize lvl1ProgWritten as an empty array
                          'lvl2ProgVoice': [], // Initialize lvl2ProgVoice as an empty array
                          'lvl2ProgWritten': [], // Initialize lvl2ProgWritten as an empty array
                          'lvl3ProgVoice': [], // Initialize lvl3ProgVoice as an empty array
                          'lvl3ProgWritten': [], // Initialize lvl3ProgWritten as an empty array
                        })
                        .then((_) {
                      print("User info saved to Firestore");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInScreen()));
                    }).catchError((error) {
                      print("Error saving user info to Firestore: ${error.toString()}");
                    });
                  }).catchError((error) {
                    print("Error ${error.toString()}");
                  });
                })
              ],
            ),
          ))),
    );
  }
}
