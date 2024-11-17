class CompletedQuestionsState {
  final List<String> writtenQuestions;
  final List<String> voiceQuestions;
  final bool isLoading;

  CompletedQuestionsState({
    this.writtenQuestions = const [],
    this.voiceQuestions = const [],
    this.isLoading = true,
  });

  CompletedQuestionsState copyWith({
    List<String>? writtenQuestions,
    List<String>? voiceQuestions,
    bool? isLoading,
  }) {
    return CompletedQuestionsState(
      writtenQuestions: writtenQuestions ?? this.writtenQuestions,
      voiceQuestions: voiceQuestions ?? this.voiceQuestions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}