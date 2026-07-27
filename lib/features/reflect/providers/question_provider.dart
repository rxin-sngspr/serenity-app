import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../repositories/question_repository.dart';
import '../../../core/database/app_database.dart';

/// Loads all questions from the JSON bundle.
final allQuestionsProvider = FutureProvider<List<QuestionItem>>((ref) {
  return QuestionRepository.loadQuestions();
});

/// In-memory counter for question refreshes (not persisted in DB).
///
/// Used to cycle to the next unique question on each "New Question" tap.
final questionRefreshCountProvider = StateProvider<int>((ref) => 0);

/// Notifier for incrementing the question refresh count.
final questionRefreshCountNotifierProvider =
    Provider<QuestionRefreshCountNotifier>((ref) {
  return QuestionRefreshCountNotifier(ref);
});

class QuestionRefreshCountNotifier {
  final Ref _ref;
  QuestionRefreshCountNotifier(this._ref);

  void increment() {
    _ref.read(questionRefreshCountProvider.notifier).state++;
  }
}

/// The current question to display, cycling through unanswered questions.
///
/// Uses a date-based offset plus a refresh count so you get unlimited unique
/// questions per day. Filters out already-answered question IDs so you never
/// see the same question twice.
final currentQuestionProvider = Provider<QuestionItem?>((ref) {
  final questions = ref.watch(allQuestionsProvider).valueOrNull;
  final refreshCount = ref.watch(questionRefreshCountProvider);
  if (questions == null || questions.isEmpty) return null;

  final answeredIds = ref.watch(answeredQuestionIdsProvider).valueOrNull;
  final unanswered = answeredIds == null
      ? questions
      : questions.where((q) => !answeredIds.contains(q.id)).toList();

  if (unanswered.isEmpty) return null;

  final dayOffset =
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final index = (dayOffset + refreshCount) % unanswered.length;
  return unanswered[index];
});

/// Set of question IDs that have already been answered locally.
final answeredQuestionIdsProvider = FutureProvider<Set<int>>((ref) async {
  final dao = ref.watch(questionAnswersDaoProvider);
  return dao.getAnsweredQuestionIds();
});

/// Today's saved answer (if any).
final todayAnswerProvider = FutureProvider<QuestionAnswer?>((ref) async {
  final dao = ref.watch(questionAnswersDaoProvider);
  return dao.getAnswerForDate(DateTime.now());
});

/// All past question answers.
final allAnswersProvider = FutureProvider<List<QuestionAnswer>>((ref) async {
  final dao = ref.watch(questionAnswersDaoProvider);
  return dao.getAllAnswers();
});
