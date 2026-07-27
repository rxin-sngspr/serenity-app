import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/story/providers/home_providers.dart';

/// Compact stats bar showing relationship metrics.
///
/// Reads [relationshipStatsProvider] and displays days together, memory count,
/// and milestone count. If start_date is not set, shows a prompt instead.
class HomeStatsBar extends ConsumerWidget {
  const HomeStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(relationshipStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: statsAsync.when(
        data: (stats) {
          if (stats.daysTogether == null) {
            return _buildNoStartDate(context, theme);
          }
          return _buildStatsRow(context, theme, stats);
        },
        loading: () => const SizedBox(height: 40),
        error: (_, _) => const SizedBox(height: 40),
      ),
    );
  }

  Widget _buildNoStartDate(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendarHeart,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Set your start date \u2192',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    ThemeData theme,
    ({int? daysTogether, int memoryCount, int milestoneCount}) stats,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _StatItem(
            icon: LucideIcons.heart,
            value: '${stats.daysTogether}',
            label: 'days together',
            theme: theme,
          ),
          _StatItem(
            icon: LucideIcons.pencil,
            value: '${stats.memoryCount}',
            label: 'memories',
            theme: theme,
          ),
          _StatItem(
            icon: LucideIcons.star,
            value: '${stats.milestoneCount}',
            label: 'milestones',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
