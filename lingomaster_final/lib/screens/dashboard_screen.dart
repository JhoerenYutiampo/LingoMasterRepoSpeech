import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingomaster_final/screens/profile.dart';
import 'package:lingomaster_final/screens/level_detail_screen.dart';
import 'package:lingomaster_final/utlis/color_utils.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentXP = 0;
  int lvl1Prog = 0;
  int lvl2Prog = 0;
  int lvl3Prog = 0;
  final int totalQuestions = 5; // number of questions

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch user data from Firestore
  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentXP = userDoc['exp'] ?? 0;
          lvl1Prog = userDoc['lvl1Prog'] ?? 0;
          lvl2Prog = userDoc['lvl2Prog'] ?? 0;
          lvl3Prog = userDoc['lvl3Prog'] ?? 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress1 = lvl1Prog / totalQuestions;
    double progress2 = lvl2Prog / totalQuestions;
    double progress3 = lvl3Prog / totalQuestions;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("5E6148"),
              hexStringToColor("9546C4"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dashboard text and profile icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ProfilePage()), // Redirect to profile page
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Current XP:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$currentXP XP",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // GestureDetector for Level 1
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelDetailScreen(
                                levelTitle: "Level 1: Characters",
                                collectionName: "characters",
                                currentProgress: lvl1Prog,
                                totalQuestions: totalQuestions,
                              ),
                            ),
                          );
                        },
                        child: _buildProgressBox("Level 1 Progress", progress1, lvl1Prog),
                      ),

                      // GestureDetector for Level 2
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelDetailScreen(
                                levelTitle: "Level 2: Words",
                                collectionName: "words",
                                currentProgress: lvl2Prog,
                                totalQuestions: totalQuestions,
                              ),
                            ),
                          );
                        },
                        child: _buildProgressBox("Level 2 Progress", progress2, lvl2Prog),
                      ),

                      // GestureDetector for Level 3
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelDetailScreen(
                                levelTitle: "Level 3: Phrases",
                                collectionName: "phrases",
                                currentProgress: lvl3Prog,
                                totalQuestions: totalQuestions,
                              ),
                            ),
                          );
                        },
                        child: _buildProgressBox("Level 3 Progress", progress3, lvl3Prog),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build a progress box
  Widget _buildProgressBox(String title, double progress, int currentProg) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 20,
          ),
          const SizedBox(height: 10),
          Text(
            "$currentProg / $totalQuestions",
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }
  
}
