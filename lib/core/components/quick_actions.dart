import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Three horizontal action tiles: New Memory, Reflect, New Milestone.
///
/// Each tile is 100x72px with a dark surface background, a Lucide icon,
/// and a label. Navigation callbacks are passed in.
class QuickActions extends StatelessWidget {
  final VoidCallback? onNewMemory;
  final VoidCallback? onReflect;
  final VoidCallback? onNewMilestone;

  const QuickActions({
    super.key,
    this.onNewMemory,
    this.onReflect,
    this.onNewMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: LucideIcons.pencil,
              label: 'Memory',
              backgroundColor: const Color(0xFF2C2C2E),
              iconColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.onSurfaceVariant,
              onTap: onNewMemory,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: LucideIcons.sparkles,
              label: 'Reflect',
              backgroundColor: const Color(0xFF2C2C2E),
              iconColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.onSurfaceVariant,
              onTap: onReflect,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: LucideIcons.star,
              label: 'Milestone',
              backgroundColor: const Color(0xFF2C2C2E),
              iconColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.onSurfaceVariant,
              onTap: onNewMilestone,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.labelColor,
    this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.94);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        _onTapUp(details);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 24, color: widget.iconColor),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
