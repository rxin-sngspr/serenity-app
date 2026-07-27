import 'package:drift/drift.dart';
import '../app_database.dart';

class QuestionAnswersDao {
  final AppDatabase db;
  QuestionAnswersDao(this.db);

  Future<QuestionAnswer?> getAnswerForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (db.select(db.questionAnswers)
          ..where((t) => t.dateAnswered.isBetween(Variable(start), Variable(end))))
        .getSingleOrNull();
  }

  Future<QuestionAnswer?> getAnswerForQuestion(int questionId) =>
      (db.select(db.questionAnswers)
            ..where((t) => t.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<List<QuestionAnswer>> getAllAnswers() =>
      (db.select(db.questionAnswers)
            ..orderBy([(t) => OrderingTerm(expression: t.dateAnswered, mode: OrderingMode.desc)]))
          .get();

  Future<int> saveAnswer(QuestionAnswersCompanion entry) =>
      db.into(db.questionAnswers).insert(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<List<QuestionAnswer>> getAnswersByUser(String userId, {int limit = 5}) async {
    return (db.select(db.questionAnswers)
      ..where((t) => t.createdBy.equals(userId))
      ..orderBy([(t) => OrderingTerm(expression: t.dateAnswered, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();
  }

  /// Returns the set of question IDs that have already been answered locally.
  Future<Set<int>> getAnsweredQuestionIds() async {
    final rows = await (db.select(db.questionAnswers)).get();
    return rows.map((r) => r.questionId).toSet();
  }

  Future<int> deleteAnswer(int id) =>
      (db.delete(db.questionAnswers)..where((t) => t.id.equals(id))).go();
}
