import 'package:flutter/material.dart';

/// Category pill badge matching the visualizer .dq-category spec.
///
/// Pill shape, primary background, white uppercase text.
class CategoryBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;

  const CategoryBadge({
    super.key,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
