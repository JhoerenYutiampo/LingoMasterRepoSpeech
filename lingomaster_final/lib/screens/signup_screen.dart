import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingomaster_final/screens/signin_screen.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final VoidCallback? onVisibilityToggle;
  final bool showVisibilityToggle;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.showVisibilityToggle = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        floatingLabelStyle: TextStyle(
          backgroundColor: Colors.white.withOpacity(0.9),
          height: 0.1,
        ),
        labelStyle: TextStyle(
          backgroundColor: Colors.white.withOpacity(0.9),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  _SignUpScreen createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final TextEditingController _userNameTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _userNameTextController.dispose();
    _emailTextController.dispose();
    _passwordTextController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Account created successfully! Please sign in.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailTextController.text.trim(),
        password: _passwordTextController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'username': _userNameTextController.text.trim(),
            'email': _emailTextController.text.trim(),
            'exp': 0,
            'hearts': 0,
            'isAdmin': false,
            'currentLevel': 0,
            'onBoarded': false,
            'lvl1ProgVoice': [],
            'lvl1ProgWritten': [],
            'lvl2ProgVoice': [],
            'lvl2ProgWritten': [],
            'lvl3ProgVoice': [],
            'lvl3ProgWritten': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          errorMessage = 'Please enter a stronger password';
          break;
      }
      
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("5E6148"),
              hexStringToColor("9546C4")
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _userNameTextController,
                    labelText: "Username",
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailTextController,
                    labelText: "Email",
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordTextController,
                    labelText: "Password",
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    showVisibilityToggle: true,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: "Confirm Password",
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    showVisibilityToggle: true,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordTextController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}