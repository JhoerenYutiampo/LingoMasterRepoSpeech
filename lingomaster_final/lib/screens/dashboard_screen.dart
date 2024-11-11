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
  final int totalQuestions = 5;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

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
          children: [
            // Updated Header Section
            Container(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dashboard",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.person, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
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
                      Text(
                        "Your Current XP:",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$currentXP XP",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Level 1 Progress
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
                        child: _buildProgressBox(
                            "Level 1 Progress", progress1, lvl1Prog),
                      ),
                      const SizedBox(height: 20),

                      // Level 2 Progress
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
                        child: _buildProgressBox(
                            "Level 2 Progress", progress2, lvl2Prog),
                      ),
                      const SizedBox(height: 20),

                      // Level 3 Progress
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
                        child: _buildProgressBox(
                            "Level 3 Progress", progress3, lvl3Prog),
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
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blueAccent.withOpacity(0.7)),
            minHeight: 18,
          ),
          const SizedBox(height: 8),
          Text(
            "$currentProg / $totalQuestions",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
