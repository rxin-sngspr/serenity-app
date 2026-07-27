import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/database/app_database.dart';

class MilestoneBadge extends StatelessWidget {
  final Milestone milestone;

  const MilestoneBadge({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorHex = milestone.color;
    final color = colorHex != null
        ? Color(int.parse(colorHex.substring(1), radix: 16) | 0xFF000000)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(77), width: 1),
      ),
      color: color.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForMilestone(milestone.icon ?? 'star'),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (milestone.description != null &&
                      milestone.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        milestone.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(LucideIcons.sparkles, size: 14, color: Colors.amber),
          ],
        ),
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
      case 'ring': return LucideIcons.gem;
      default: return LucideIcons.star;
    }
  }
}
