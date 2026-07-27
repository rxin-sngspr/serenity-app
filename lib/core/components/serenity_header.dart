import 'package:flutter/material.dart';

/// App header/logo matching the visualizer .header-logo and .header-tagline spec.
///
/// "Serenity" in Cormorant Garamond 36px/600
/// "your story together" in Inter 14px/400 uppercase
class SerenityHeader extends StatelessWidget {
  final String tagline;

  const SerenityHeader({
    super.key,
    this.tagline = 'your story together',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Serenity',
          style: TextStyle(fontFamily: 'Cormorant Garamond', 
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tagline.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            letterSpacing: 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
