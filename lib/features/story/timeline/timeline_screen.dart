import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/timeline_provider.dart';
import '../models/timeline_entry.dart';
import 'widgets/date_group_header.dart';
import 'calendar_provider.dart';
import '../../../core/components/calendar_widget.dart';
import '../../../core/components/section_divider.dart';
import '../../../core/components/timeline_card.dart';
import '../../../core/components/milestone_chip.dart';
import '../../../core/components/appreciation_block.dart';
import '../../../core/components/home_stats_bar.dart';
import '../../../core/components/reflection_nudge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/sync_status_indicator.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  bool _calendarExpanded = true;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineAsync = ref.watch(timelineProvider);
    final calendarDatesAsync = ref.watch(calendarDatesProvider(
      DateTime(DateTime.now().year, DateTime.now().month, 1),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Story',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          const SyncStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            onPressed: () async {
              final pickedDate = await context.pushNamed<DateTime>('calendar');
              if (pickedDate != null) {
                setState(() => _selectedDate = pickedDate);
              }
            },
            tooltip: 'Calendar',
          ),
        ],
      ),
      body: timelineAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyTimeline();
          }

          final filteredGroups = _selectedDate != null
              ? groups.where((g) =>
                  g.date.year == _selectedDate!.year &&
                  g.date.month == _selectedDate!.month &&
                  g.date.day == _selectedDate!.day)
                  .toList()
              : groups;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(timelineProvider.future),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // 1. Relationship Stats Bar
                const HomeStatsBar(),

                // 2. Daily Reflection Nudge
                const ReflectionNudge(),

                // 3. Calendar (collapsible)
                calendarDatesAsync.when(
                  data: (dates) => Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Row(
                            children: [
                              Icon(
                                _calendarExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Calendar',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_calendarExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child:                           CalendarWidget(
                            datesWithEntries: dates,
                            selectedDate: _selectedDate,
                            onDayTapped: (date) {
                              setState(() {
                                final isSame = _selectedDate != null &&
                                    _selectedDate!.year == date.year &&
                                    _selectedDate!.month == date.month &&
                                    _selectedDate!.day == date.day;
                                _selectedDate = isSame ? null : date;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // 5. Filter banner
                if (_selectedDate != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _FilterChip(
                      date: _selectedDate!,
                      onClear: () => setState(() => _selectedDate = null),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // 6. Section divider
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SectionDivider(label: 'Timeline'),
                ),

                // 7. Date groups
                if (filteredGroups.isEmpty && _selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Center(
                      child: Text(
                        'No entries on this day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredGroups.map((group) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DateGroupHeader(date: group.date),
                      ...group.entries.map((entry) {
                        return switch (entry) {
                          MemoryEntry(:final memory, :final tags, :final photoPath, :final createdBy) =>
                            _buildMemoryCard(context, memory, tags, photoPath, createdBy: createdBy),
                          MilestoneEntry(:final milestone, :final createdBy) =>
                            _buildMilestoneCard(context, milestone, createdBy: createdBy),
                        };
                      }),
                    ],
                  )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Something went wrong.\n$err',
              textAlign: TextAlign.center),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showCreateOptions(context);
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildMemoryCard(
      BuildContext context, dynamic memory, List<Tag> tags, String? photoPath, {String? createdBy}) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isPartner = createdBy != null && createdBy != currentUserId;
    final isAppreciation = memory.type == 'appreciation';

    if (isAppreciation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppreciationBlock(
          title: memory.title,
          body: memory.body,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.pushNamed(
          'memory-detail',
          pathParameters: {'memoryId': memory.id.toString()},
        ),
        child: TimelineCard(
          name: isPartner ? 'Partner' : 'You',
          date: _formatTime(memory.date),
          body: memory.body,
          isQuote: true,
          tags: tags,
          photoPath: photoPath,
          avatarColor: isPartner
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(BuildContext context, dynamic milestone, {String? createdBy}) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isPartner = createdBy != null && createdBy != currentUserId;
    final colorHex = milestone.color;
    final color = colorHex != null
        ? Color(int.parse(colorHex.substring(1), radix: 16) | 0xFF000000)
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          MilestoneChip(
            label: milestone.title,
            icon: _iconForMilestone(milestone.icon ?? 'star'),
            backgroundColor: color,
          ),
          if (isPartner) ...[
            const SizedBox(width: 8),
            Text(
              'Partner',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.pencil, size: 16,
                color: theme.colorScheme.onSurfaceVariant),
            onPressed: () => context.pushNamed(
              'create-milestone-edit',
              pathParameters: {'milestoneId': milestone.id.toString()},
            ),
            tooltip: 'Edit milestone',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  IconData _iconForMilestone(String iconName) {
    switch (iconName) {
      case 'favorite': return LucideIcons.heart;
      case 'star': return LucideIcons.star;
      case 'celebration': return LucideIcons.sparkles;
      case 'church': return LucideIcons.circle;
      case 'home': return LucideIcons.home;
      case 'flight': return LucideIcons.plane;
      case 'work': return LucideIcons.briefcase;
      case 'school': return LucideIcons.graduationCap;
      case 'pets': return LucideIcons.footprints;
      case 'diamond': return LucideIcons.gem;
      default: return LucideIcons.star;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $amPm';
  }

  void _showCreateOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(LucideIcons.pencil, color: theme.colorScheme.primary),
                title: Text('New Memory',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    )),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.pushNamed('create-memory');
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.messageCircle, color: theme.colorScheme.primary),
                title: Text('Reflect',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    )),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.pushNamed('reflect');
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.sparkles, color: theme.colorScheme.primary),
                title: Text('New Milestone',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    )),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.pushNamed('create-milestone');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.heart,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Your story begins here',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first memory or milestone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;

  const _FilterChip({required this.date, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.filter, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '${date.day} ${months[date.month - 1]} ${date.year}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Icon(LucideIcons.x, size: 14, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
