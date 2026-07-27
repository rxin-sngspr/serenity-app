import 'package:drift/drift.dart';

@TableIndex(name: 'memories_date_idx', columns: {#date})
@TableIndex(name: 'memories_date_type_idx', columns: {#date, #type})
class Memories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withDefault(const Constant('memory'))();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get coupleId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
