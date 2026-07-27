import '../../../core/database/app_database.dart';

sealed class TimelineEntry {
  final DateTime date;
  const TimelineEntry(this.date);
}

class MemoryEntry extends TimelineEntry {
  final Memory memory;
  final List<Tag> tags;
  final String? photoPath;
  final String? createdBy;

  const MemoryEntry(
    super.date,
    this.memory,
    this.tags,
    this.photoPath, {
    this.createdBy,
  });
}

class MilestoneEntry extends TimelineEntry {
  final Milestone milestone;
  final String? createdBy;

  const MilestoneEntry(
    super.date,
    this.milestone, {
    this.createdBy,
  });
}

class TimelineGroup {
  final DateTime date;
  final List<TimelineEntry> entries;

  const TimelineGroup(this.date, this.entries);
}
