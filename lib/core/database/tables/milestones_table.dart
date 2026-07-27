import 'package:drift/drift.dart';

@TableIndex(name: 'milestones_date_idx', columns: {#date})
class Milestones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get type => text().withDefault(const Constant('milestone'))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get coupleId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
