import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingomaster_final/screens/level_detail/providers/completed_questions_provider.dart';
import 'package:lingomaster_final/screens/draw_screen.dart';
import 'package:lingomaster_final/screens/level_detail/widgets/practice_button.dart';
import 'package:lingomaster_final/screens/voice_screen.dart';

class QuestionCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  final String collectionName;
  final VoidCallback onRefresh;

  const QuestionCard({
    super.key,
    required this.doc,
    required this.collectionName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedQuestionsProvider);
    final symbol = doc['english'];
    final isWrittenCompleted = state.writtenQuestions.contains(doc.id);
    final isVoiceCompleted = state.voiceQuestions.contains(doc.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                symbol,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Row(
              children: [
                PracticeButton(
                  icon: Icons.edit,
                  color: Colors.indigo,
                  isCompleted: isWrittenCompleted,
                  onPressed: () => _navigateToDrawScreen(context),
                ),
                PracticeButton(
                  icon: Icons.mic,
                  color: Colors.redAccent,
                  isCompleted: isVoiceCompleted,
                  onPressed: () => _navigateToVoiceScreen(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDrawScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawScreen(
          targetHiragana: doc['hiragana'],
          questionId: doc.id,
          collectionName: collectionName,
        ),
      ),
    ).then((_) => onRefresh());
  }

  void _navigateToVoiceScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceScreen(
          hiragana: doc['hiragana'],
          english: doc['english'],
          audio: doc['audio'],
          pronunciation: doc['pronunciation'],
          questionId: doc.id,
          collectionName: collectionName,
        ),
      ),
    ).then((_) => onRefresh());
  }
}