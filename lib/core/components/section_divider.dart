import 'package:flutter/material.dart';

/// Section divider with label + line matching the visualizer .reflect-divider spec.
///
/// APPRECIATION LOG ────────────────────
class SectionDivider extends StatelessWidget {
  final String label;

  const SectionDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
