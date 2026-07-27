import 'package:drift/drift.dart';

@TableIndex(name: 'tag_assignments_memory_id_idx', columns: {#memoryId})
@TableIndex(name: 'tag_assignments_tag_id_idx', columns: {#tagId})
class TagAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tagId => integer()();
  IntColumn get memoryId => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
