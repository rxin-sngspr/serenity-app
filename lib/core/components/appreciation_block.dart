import 'package:flutter/material.dart';

/// Appreciation entry block matching the visualizer .tl-appreciation spec.
///
/// ── Appreciation Log ──────  → section divider
///
/// ┌─────────────────────────┐
/// │ ♥  Appreciation Title  │  → gradient bg, left border 3px primary
/// │                        │
/// │ Appreciation text here │  → body Cormorant italic
/// └────────────────────────┘
class AppreciationBlock extends StatelessWidget {
  final String title;
  final String body;
  final Color? accentColor;

  const AppreciationBlock({
    super.key,
    required this.title,
    required this.body,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.scaffoldBackgroundColor,
          ],
        ),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ♥ icon + title
          Row(
            children: [
              Text(
                '\u2665',
                style: TextStyle(
                  fontSize: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Body text
          Text(
            body,
            style: TextStyle(fontFamily: 'Cormorant Garamond', 
              fontSize: 15,
              height: 22 / 15,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
