import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  int currentXP;
  int hearts;
  int currentLevel;
  Map<String, int> totalQuestions;
  Map<String, int> completedQuestions;

  UserProgress({
    required this.currentXP,
    required this.hearts,
    required this.currentLevel,
    required this.totalQuestions,
    required this.completedQuestions,
  });

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    currentXP = data['exp'] ?? 0;
    hearts = data['hearts'] ?? 0;
    currentLevel = data['currentLevel'] ?? 0;
  }

  void updateQuestionsData(List<Map<String, int>> questionsData) {
    final levels = ['characters', 'words', 'phrases'];
    for (var i = 0; i < levels.length; i++) {
      totalQuestions[levels[i]] = questionsData[i]['total'] ?? 0;
      completedQuestions[levels[i]] = questionsData[i]['completed'] ?? 0;
    }
  }

  double getProgress(String level) {
    final total = totalQuestions[level] ?? 1;
    final completed = completedQuestions[level] ?? 0;
    return completed / total;
  }
}