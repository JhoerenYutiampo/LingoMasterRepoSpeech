import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingomaster_final/Admin/add_question.dart';
import 'package:lingomaster_final/screens/dashboard/models/user_progress.dart';
import 'package:lingomaster_final/screens/level_detail/level_detail_screen.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';
import 'package:lingomaster_final/screens/dashboard/widgets/progress_box.dart';
import 'package:lingomaster_final/screens/dashboard/widgets/user_stats_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DatabaseMethods _databaseMethods;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  
  final UserProgress _userProgress = UserProgress(
    currentXP: 0,
    hearts: 0,
    currentLevel: 0,
    totalQuestions: {},
    completedQuestions: {},
  );

  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _databaseMethods = DatabaseMethods();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _setupUserDataListener();
    await _fetchQuestionData();
    await _checkAdminStatus();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupUserDataListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(_handleUserDataUpdate);
  }

  void _handleUserDataUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    
    setState(() {
      _userProgress.updateFromSnapshot(snapshot);
    });
  }

  Future<void> _fetchQuestionData() async {
    final questionsData = await Future.wait([
      _fetchLevelQuestions('characters'),
      _fetchLevelQuestions('words'),
      _fetchLevelQuestions('phrases'),
    ]);

    setState(() {
      _userProgress.updateQuestionsData(questionsData);
    });
  }

  Future<Map<String, int>> _fetchLevelQuestions(String level) async {
    final total = await _databaseMethods.getTotalQuestionsForLevel(level);
    final written = await _databaseMethods.getCompletedQuestions(
      _getLevelNumber(level), 
      'written'
    );
    final voice = await _databaseMethods.getCompletedQuestions(
      _getLevelNumber(level), 
      'voice'
    );

    return {
      'total': total * 2,
      'completed': written.length + voice.length,
    };
  }

  int _getLevelNumber(String level) {
    switch (level) {
      case 'characters': return 1;
      case 'words': return 2;
      case 'phrases': return 3;
      default: return 1;
    }
  }

  Future<void> _navigateToLevel(BuildContext context, String level) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelDetailScreen(
          levelTitle: "Level ${_getLevelNumber(level)}: ${level.capitalize()}",
          collectionName: level,
          currentProgress: _userProgress.completedQuestions[level] ?? 0,
          totalQuestions: _userProgress.totalQuestions[level] ?? 0,
        ),
      ),
    );
    _fetchQuestionData();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _databaseMethods.getIsAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hexStringToColor("CB2B93"),
            hexStringToColor("5E6148"),
            hexStringToColor("9546C4"),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _initializeData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: UserStatsHeader(
                  level: _userProgress.currentLevel,
                  hearts: _userProgress.hearts,
                  xp: _userProgress.currentXP,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    ...['characters', 'words', 'phrases'].map((level) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ProgressBox(
                          levelName: "Level ${_getLevelNumber(level)}: ${level.capitalize()}",
                          progress: _userProgress.getProgress(level),
                          completed: _userProgress.completedQuestions[level] ?? 0,
                          total: _userProgress.totalQuestions[level] ?? 0,
                          onTap: () => _navigateToLevel(context, level),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _isAdmin 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddQuestionPage()),
                );
              },
              label: const Text('Add Question'),
              icon: const Icon(Icons.add),
              backgroundColor: hexStringToColor("CB2B93"),
            )
          : null,
      ),
    );
  }
}