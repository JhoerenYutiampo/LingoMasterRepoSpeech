import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingomaster_final/Admin/add_question.dart';
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
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    setupUserDataListener();
    fetchTotalQuestions();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  void setupUserDataListener() {
  User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userDataSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            currentXP = snapshot.data()?['exp'] ?? 0;
            hearts = snapshot.data()?['hearts'] ?? 0;
            currentLevel = snapshot.data()?['currentLevel'] ?? 0;
          });
          refreshData();
        }
      });
    }
  }

  void refreshData() {
    setupUserDataListener();
    fetchTotalQuestions();
    fetchCompletedQuestions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          refreshData();
        },
        child: Container(
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
                            Icon(Icons.favorite, color: Colors.red, size: 28),
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
                  physics: AlwaysScrollableScrollPhysics(),
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
                          ).then((_) => refreshData()),
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
                          ).then((_) => refreshData()),
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
                          ).then((_) => refreshData()),
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

              // Button at the bottom to route to Assesment
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddQuestionPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Go to Add Question',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBox(
      String levelName, double progress, int completed, int total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            levelName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            minHeight: 10,
          ),
          SizedBox(height: 10),
          Text(
            "$completed/$total",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}