import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../models/timeline_entry.dart';

final timelineProvider = FutureProvider<List<TimelineGroup>>((ref) async {
  final dao = ref.watch(timelineDaoProvider);
  return dao.getTimeline();
});

