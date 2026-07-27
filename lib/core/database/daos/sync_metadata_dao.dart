import 'package:drift/drift.dart';
import '../app_database.dart';

class SyncMetadataDao {
  final AppDatabase db;
  SyncMetadataDao(this.db);

  Future<String?> get(String key) async {
    final row =
        await (db.select(db.syncMetadata)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.syncMetadata).insert(
          SyncMetadataCompanion.insert(key: key, value: Value(value)),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> remove(String key) async {
    await (db.delete(db.syncMetadata)..where((t) => t.key.equals(key))).go();
  }

  /// Convenience getter for a sync timestamp by entity type.
  /// Stores the value under `last_sync_<entityType>`.
  Future<DateTime?> getLastSyncTimestamp(String entityType) async {
    final value = await get('last_sync_$entityType');
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Convenience setter for a sync timestamp by entity type.
  /// Stores the value under `last_sync_<entityType>`.
  Future<void> setLastSyncTimestamp(
      String entityType, DateTime timestamp) async {
    await set('last_sync_$entityType', timestamp.toIso8601String());
  }
}
