import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingomaster_final/screens/level_detail/models/completed_question_state.dart';
import 'package:lingomaster_final/service/databaseMethods.dart';

final completedQuestionsProvider = StateNotifierProvider<CompletedQuestionsNotifier, CompletedQuestionsState>((ref) {
  return CompletedQuestionsNotifier();
});

class CompletedQuestionsNotifier extends StateNotifier<CompletedQuestionsState> {
  CompletedQuestionsNotifier() : super(CompletedQuestionsState());

  Future<void> loadCompletedQuestions(DatabaseMethods databaseMethods, int level) async {
    try {
      final writtenQuestions = await databaseMethods.getCompletedQuestions(level, 'written');
      final voiceQuestions = await databaseMethods.getCompletedQuestions(level, 'voice');
      
      state = state.copyWith(
        writtenQuestions: writtenQuestions,
        voiceQuestions: voiceQuestions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}