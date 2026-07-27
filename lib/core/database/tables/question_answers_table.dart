import 'package:drift/drift.dart';

@TableIndex(name: 'question_answers_date_idx', columns: {#dateAnswered})
class QuestionAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  TextColumn get category => text()();
  TextColumn get answerText => text()();
  DateTimeColumn get dateAnswered => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get coupleId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
