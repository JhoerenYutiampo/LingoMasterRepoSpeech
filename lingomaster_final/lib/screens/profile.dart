import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingomaster_final/component/text_box.dart';
import 'package:lingomaster_final/screens/profile_picture.dart';
import 'package:lingomaster_final/screens/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String? email;
  String? bio;
  int exp;

  AppUser({this.email, this.bio, this.exp = 0});
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SharedPreferences _prefs; // SharedPreferences instance
  late AppUser currentUser;

  @override
  void initState() {
    super.initState();
    _initPreferences();
    currentUser = AppUser(
      email: FirebaseAuth.instance.currentUser!.email,
      bio: '', // Initialize bio to empty string
      exp: 0,
    );
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc = await usersCollection.doc(currentUser.email).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        currentUser.bio = userData['bio'] ?? '';
        currentUser.exp = userData['exp'] ?? 0;
      });
    }
  }

  //Calculate level from exp
  Map<String, dynamic> calculateLevel(int exp) {
    int level = 0;
    int expNeededForNextLevel = 10;
    int remainingExp = exp;

    while (remainingExp >= expNeededForNextLevel) {
      remainingExp -= expNeededForNextLevel;
      level++;
      expNeededForNextLevel += 10;
    }

    return {
      'level': level,
      'currentExp': remainingExp,
      'expNeededForNextLevel': expNeededForNextLevel - remainingExp,
    };
  }

  // Initialize SharedPreferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Retrieve bio from local storage
    setState(() {
      currentUser.bio = _prefs.getString('bio') ?? '';
    });
  }

  // Reference to Firestore collection
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Edit field
  Future<void> editField(String field) async {
    if (field == 'bio') {
      String? newBio = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String bio = currentUser.bio ?? '';
          return AlertDialog(
            title: const Text('Edit Bio'),
            content: TextField(
              onChanged: (value) {
                bio = value;
              },
              decoration: const InputDecoration(
                hintText: 'Enter your bio',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(bio);
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (newBio != null) {
        setState(() {
          currentUser.bio = newBio;
        });

        // Update bio in local storage
        _prefs.setString('bio', newBio);

        // Update bio in Firestore
        await usersCollection.doc(currentUser.email).set({
          'bio': newBio,
        });
      }
    }
  }

  // Logout method
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  Widget _buildExpInfo() {
  Map<String, dynamic> levelInfo = calculateLevel(currentUser.exp);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Level: ${levelInfo['level']}'),
      //Text('Current EXP: ${levelInfo['currentExp']}'),
      Text('EXP needed for next level: ${levelInfo['expNeededForNextLevel']}'),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text("P R O F I L E"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              children: [
                // Profile pic
                Center(
                  child: ProfilePicture(),
                ),
                const SizedBox(height: 50),

                // User email
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 50),

                // User details
                const Text(
                  'My Details',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Bio
                MyTextBox(
                  text: currentUser.bio ?? '',
                  sectionName: 'bio',
                  onPressed: () => editField('bio'),
                ),
                const SizedBox(height: 50),

                // EXP and Level info
                _buildExpInfo(),
                const SizedBox(height: 50),
              ],
            ),
          ),

          // Logout button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(25.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              gradient: const LinearGradient(
                colors: [Colors.black, Color.fromARGB(255, 87, 121, 64)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(10),
                backgroundColor:
                    Colors.transparent, // This is important for the gradient
                shadowColor: Colors
                    .transparent, // Remove shadow to keep the gradient clean
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}