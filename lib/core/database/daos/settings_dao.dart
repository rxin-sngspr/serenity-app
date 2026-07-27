import 'package:drift/drift.dart';
import '../app_database.dart';

class SettingsDao {
  final AppDatabase db;
  SettingsDao(this.db);

  Future<String?> get(String key) async {
    final row =
        await (db.select(db.settings)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.settings).insert(
      SettingsCompanion.insert(key: key, value: Value(value)),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> remove(String key) async {
    await (db.delete(db.settings)..where((t) => t.key.equals(key))).go();
  }
}
