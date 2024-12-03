import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingomaster_final/screens/level_detail/providers/completed_questions_provider.dart';
import 'package:lingomaster_final/screens/assessment/assessment_screen.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/assessment_button.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/custom_app_bar.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/heart_dialog.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/progress_card.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/questions_list.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';
import 'package:lingomaster_final/utlis/color_utils.dart';

class LevelDetailScreen extends ConsumerStatefulWidget {
  final String levelTitle;
  final String collectionName;
  final int currentProgress;
  final int totalQuestions;

  const LevelDetailScreen({
    super.key,
    required this.levelTitle,
    required this.collectionName,
    required this.currentProgress,
    required this.totalQuestions,
  });

  @override
  ConsumerState<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends ConsumerState<LevelDetailScreen> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final ScrollController _scrollController = ScrollController();

  int get _level => switch (widget.collectionName) {
    'characters' => 1,
    'words' => 2,
    'phrases' => 3,
    _ => 1,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(completedQuestionsProvider.notifier)
         .loadCompletedQuestions(_databaseMethods, _level);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkHeartsAndNavigate() async {
    try {
      final currentHearts = await _databaseMethods.getUserHearts();
      
      if (!mounted) return;

      if (currentHearts <= 0) {
        _showNoHeartsDialog();
      } else {
        _navigateToAssessment();
      }
    } catch (e) {
      _showErrorSnackBar();
    }
  }

  void _showNoHeartsDialog() {
    showDialog(
      context: context,
      builder: (context) => const HeartDialog(),
    );
  }

  void _navigateToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentScreen(widget.collectionName),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error checking hearts. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: widget.levelTitle),
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
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
            ProgressCard(
              currentProgress: widget.currentProgress,
              totalQuestions: widget.totalQuestions,
            ),
            Expanded(
              child: QuestionsList(
                collectionName: widget.collectionName,
                scrollController: _scrollController,
                onRefresh: () => ref.read(completedQuestionsProvider.notifier)
                    .loadCompletedQuestions(_databaseMethods, _level),
              ),
            ),
            AssessmentButton(onPressed: _checkHeartsAndNavigate),
          ],
        ),
      ),
    );
  }
}