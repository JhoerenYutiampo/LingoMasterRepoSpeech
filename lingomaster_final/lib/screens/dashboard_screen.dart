import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingomaster_final/screens/profile.dart';
import 'package:lingomaster_final/screens/level_detail_screen.dart';
import 'package:lingomaster_final/service/database.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentXP = 0;
  int hearts = 0;
  int currentLevel = 0;
  Map<String, int> totalQuestions = {};
  Map<String, int> completedQuestions = {};
  final DatabaseMethods _databaseMethods = DatabaseMethods();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTotalQuestions();
  }

  void fetchTotalQuestions() async {
    // Get the number of documents and multiply by 2 for written and voice
    int charactersTotal = await _databaseMethods.getTotalQuestionsForLevel('characters');
    int wordsTotal = await _databaseMethods.getTotalQuestionsForLevel('words');
    int phrasesTotal = await _databaseMethods.getTotalQuestionsForLevel('phrases');

    setState(() {
      totalQuestions['characters'] = charactersTotal * 2; // Multiply by 2 for written and voice
      totalQuestions['words'] = wordsTotal * 2;
      totalQuestions['phrases'] = phrasesTotal * 2;
    });
    fetchCompletedQuestions();
  }

  void fetchCompletedQuestions() async {
    // Fetch completed questions for each level (both written and voice)
    List<String> lvl1Written = await _databaseMethods.getCompletedQuestions(1, 'written');
    List<String> lvl1Voice = await _databaseMethods.getCompletedQuestions(1, 'voice');
    List<String> lvl2Written = await _databaseMethods.getCompletedQuestions(2, 'written');
    List<String> lvl2Voice = await _databaseMethods.getCompletedQuestions(2, 'voice');
    List<String> lvl3Written = await _databaseMethods.getCompletedQuestions(3, 'written');
    List<String> lvl3Voice = await _databaseMethods.getCompletedQuestions(3, 'voice');

    setState(() {
      completedQuestions['characters'] = lvl1Written.length + lvl1Voice.length;
      completedQuestions['words'] = lvl2Written.length + lvl2Voice.length;
      completedQuestions['phrases'] = lvl3Written.length + lvl3Voice.length;
    });
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
          hearts = userDoc['hearts'] ?? 0;
          currentLevel = userDoc['currentLevel'] ?? 0;  // Fetch current level
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Level: $currentLevel",
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
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              color: Colors.red,
                              size: 28),
                          SizedBox(width: 4),
                          Text(
                            "$hearts/5",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.person,
                                color: Colors.white, size: 30),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfilePage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: currentXP / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9)),
                          minHeight: 20,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "XP",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                      const SizedBox(height: 30),

                      // Level Progress Boxes
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelDetailScreen(
                              levelTitle: "Level 1: Characters",
                              collectionName: "characters",
                              currentProgress: completedQuestions['characters'] ?? 0,
                              totalQuestions: totalQuestions['characters'] ?? 0,
                            ),
                          ),
                        ),
                        child: _buildProgressBox(
                          "Level 1: Characters",
                          (completedQuestions['characters'] ?? 0) / 
                          (totalQuestions['characters'] ?? 1),
                          completedQuestions['characters'] ?? 0,
                          totalQuestions['characters'] ?? 0,
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelDetailScreen(
                              levelTitle: "Level 2: Words",
                              collectionName: "words",
                              currentProgress: completedQuestions['words'] ?? 0,
                              totalQuestions: totalQuestions['words'] ?? 0,
                            ),
                          ),
                        ),
                        child: _buildProgressBox(
                          "Level 2: Words",
                          (completedQuestions['words'] ?? 0) / 
                          (totalQuestions['words'] ?? 1),
                          completedQuestions['words'] ?? 0,
                          totalQuestions['words'] ?? 0,
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelDetailScreen(
                              levelTitle: "Level 3: Phrases",
                              collectionName: "phrases",
                              currentProgress: completedQuestions['phrases'] ?? 0,
                              totalQuestions: totalQuestions['phrases'] ?? 0,
                            ),
                          ),
                        ),
                        child: _buildProgressBox(
                          "Level 3: Phrases",
                          (completedQuestions['phrases'] ?? 0) / 
                          (totalQuestions['phrases'] ?? 1),
                          completedQuestions['phrases'] ?? 0,
                          totalQuestions['phrases'] ?? 0,
                        ),
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
  Widget _buildProgressBox(String title, double progress, int currentProg, int total) {
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
            "$currentProg / $total",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
