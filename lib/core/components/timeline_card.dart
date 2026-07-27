import 'dart:io';
import 'package:flutter/material.dart';
import '../database/app_database.dart';

/// Timeline entry card matching the visualizer .tl-card spec.
///
/// Structure:
/// ┌─────────────────────────┐
/// │ [Avatar] [Name]  [Date] │  → header
/// │                         │
/// │ Memory body text here   │  → body (Cormorant Garamond italic)
/// │                         │
/// │ [Tag1] [Tag2]          │  → tags as colored pill chips
/// │                         │
/// │ [Photo]                 │  → optional photo
/// └─────────────────────────┘
class TimelineCard extends StatelessWidget {
  final String name;
  final String date;
  final String body;
  final bool isQuote;
  final List<Tag> tags;
  final String? photoPath;
  final Color? avatarColor;
  final Widget? trailing;

  const TimelineCard({
    super.key,
    required this.name,
    required this.date,
    required this.body,
    this.isQuote = false,
    this.tags = const [],
    this.photoPath,
    this.avatarColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarBg = avatarColor ?? theme.colorScheme.secondary;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Date
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Body
          if (isQuote)
            Text(
              body,
              style: TextStyle(fontFamily: 'Cormorant Garamond', 
                fontSize: 15,
                height: 22 / 15,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),

          // Photo
          if (photoPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photoPath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Tags
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tags.map((tag) {
                  final hex = tag.color;
                  final bgColor = hex != null
                      ? Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000)
                      : theme.colorScheme.primary;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Trailing widget (e.g. milestone badge)
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
