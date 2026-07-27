import 'package:drift/drift.dart';

@TableIndex(name: 'reflections_date_idx', columns: {#date})
class Reflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get promptType => text()();
  TextColumn get promptText => text()();
  TextColumn get content => text()();
  IntColumn get moodScore => integer().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get coupleId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
