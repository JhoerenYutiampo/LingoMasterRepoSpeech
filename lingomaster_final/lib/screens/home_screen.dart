import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lingomaster_final/screens/signin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
        child: const Text("Logout"),
        onPressed: () {
          FirebaseAuth.instance.signOut().then((value) {
            print("Signed Out Successfully");
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SignInScreen()));
          });
        },
      )),
    );
  }
}
