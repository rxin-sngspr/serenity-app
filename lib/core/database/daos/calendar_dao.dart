import 'package:drift/drift.dart';
import '../app_database.dart';

class CalendarDao {
  final AppDatabase db;
  CalendarDao(this.db);

  /// Returns set of date strings (YYYY-MM-DD) that have any entries for a month.
  Future<Set<String>> getDatesWithEntries(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final dateKeys = <String>{};

    final memories = await (db.select(db.memories)
          ..where((t) => t.date.isBetween(Variable(start), Variable(end))))
        .get();
    for (final m in memories) {
      dateKeys.add('${m.date.year}-${m.date.month}-${m.date.day}');
    }

    final milestones = await (db.select(db.milestones)
          ..where((t) => t.date.isBetween(Variable(start), Variable(end))))
        .get();
    for (final m in milestones) {
      dateKeys.add('${m.date.year}-${m.date.month}-${m.date.day}');
    }

    final reflections = await (db.select(db.reflections)
          ..where((t) => t.date.isBetween(Variable(start), Variable(end))))
        .get();
    for (final r in reflections) {
      dateKeys.add('${r.date.year}-${r.date.month}-${r.date.day}');
    }

    final answers = await (db.select(db.questionAnswers)
          ..where((t) =>
              t.dateAnswered.isBetween(Variable(start), Variable(end))))
        .get();
    for (final a in answers) {
      dateKeys
          .add('${a.dateAnswered.year}-${a.dateAnswered.month}-${a.dateAnswered.day}');
    }

    return dateKeys;
  }
}
