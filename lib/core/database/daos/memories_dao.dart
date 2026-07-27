import 'package:drift/drift.dart';
import '../app_database.dart';

class MemoriesDao {
  final AppDatabase db;
  MemoriesDao(this.db);

  Future<List<Memory>> getAllMemories() =>
      (db.select(db.memories)
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
          .get();

  Future<List<Memory>> getMemoriesByType(String type) =>
      (db.select(db.memories)
        ..where((t) => t.type.equals(type))
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
          .get();

  Future<Memory?> getMemoryById(int id) =>
      (db.select(db.memories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createMemory(MemoriesCompanion entry) =>
      db.into(db.memories).insert(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<bool> updateMemory(MemoriesCompanion entry) =>
      db.update(db.memories).replace(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<int> countAll() async {
    final rows = await db
        .customSelect(
            'SELECT COUNT(*) AS cnt FROM memories WHERE is_deleted = 0')
        .get();
    return rows.first.read<int>('cnt');
  }

  Future<int> deleteMemory(int id) =>
      (db.delete(db.memories)..where((t) => t.id.equals(id))).go();

  // Media
  Future<int> addMedia(MemoryMediaCompanion media) =>
      db.into(db.memoryMedia).insert(media);

  Future<List<MemoryMediaData>> getMediaForMemory(int memoryId) =>
      (db.select(db.memoryMedia)..where((t) => t.memoryId.equals(memoryId))).get();

  Future<int> deleteMedia(int id) =>
      (db.delete(db.memoryMedia)..where((t) => t.id.equals(id))).go();

  Future<int> deleteMediaForMemory(int memoryId) =>
      (db.delete(db.memoryMedia)..where((t) => t.memoryId.equals(memoryId))).go();
}
