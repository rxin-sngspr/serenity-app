import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/memories_dao.dart';
import 'daos/milestones_dao.dart';
import 'daos/timeline_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/reflections_dao.dart';
import 'daos/question_answers_dao.dart';
import 'daos/calendar_dao.dart';
import 'daos/tags_dao.dart';
import 'daos/sync_metadata_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final memoriesDaoProvider = Provider<MemoriesDao>((ref) {
  return MemoriesDao(ref.watch(databaseProvider));
});

final milestonesDaoProvider = Provider<MilestonesDao>((ref) {
  return MilestonesDao(ref.watch(databaseProvider));
});

final timelineDaoProvider = Provider<TimelineDao>((ref) {
  return TimelineDao(ref.watch(databaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(databaseProvider));
});

final reflectionsDaoProvider = Provider<ReflectionsDao>((ref) {
  return ReflectionsDao(ref.watch(databaseProvider));
});

final questionAnswersDaoProvider = Provider<QuestionAnswersDao>((ref) {
  return QuestionAnswersDao(ref.watch(databaseProvider));
});

final calendarDaoProvider = Provider<CalendarDao>((ref) {
  return CalendarDao(ref.watch(databaseProvider));
});

final tagsDaoProvider = Provider<TagsDao>((ref) {
  return TagsDao(ref.watch(databaseProvider));
});

final syncMetadataDaoProvider = Provider<SyncMetadataDao>((ref) {
  return SyncMetadataDao(ref.watch(databaseProvider));
});
