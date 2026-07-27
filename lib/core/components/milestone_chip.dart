import 'package:flutter/material.dart';

/// Inline milestone chip matching the visualizer .milestone-badge spec.
///
/// [★ Our Anniversary]
///
/// Inline pill shape, accent background, white text, Lucide icon.
class MilestoneChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? backgroundColor;

  const MilestoneChip({
    super.key,
    required this.label,
    this.icon = Icons.star,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
