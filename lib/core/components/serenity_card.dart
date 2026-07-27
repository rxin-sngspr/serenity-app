import 'package:flutter/material.dart';

/// Base card widget matching the visualizer spec.
///
/// Padding 20px, border-radius 12px, elevation 0.
/// Optional shadow via card color (0 2px 8px rgba(0,0,0,0.15)).
class SerenityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showShadow;

  const SerenityCard({
    super.key,
    required this.child,
    this.padding,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(38),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
