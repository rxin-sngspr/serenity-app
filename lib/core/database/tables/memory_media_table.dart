import 'package:drift/drift.dart';

class MemoryMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memoryId => integer()();
  TextColumn get mimeType => text()();
  TextColumn get path => text()();
  TextColumn get coupleId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
