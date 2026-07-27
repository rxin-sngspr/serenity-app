import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/components/serenity_header.dart';
import '../../../core/database/database_provider.dart';
import '../../../features/couple/providers/couple_provider.dart';
import 'create_couple_screen.dart';
import 'join_couple_screen.dart';

class CoupleLinkingScreen extends ConsumerStatefulWidget {
  const CoupleLinkingScreen({super.key});

  @override
  ConsumerState<CoupleLinkingScreen> createState() =>
      _CoupleLinkingScreenState();
}

class _CoupleLinkingScreenState extends ConsumerState<CoupleLinkingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const SerenityHeader(),
              const SizedBox(height: 16),
              Text(
                'Connect with your partner',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              _OptionCard(
                icon: LucideIcons.link,
                title: 'Create a Couple',
                subtitle:
                    'Generate an invite code to share with your partner',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CreateCoupleScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _OptionCard(
                icon: LucideIcons.userPlus,
                title: 'Join a Couple',
                subtitle: 'Enter your partner\'s invite code',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const JoinCoupleScreen()),
                ),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () async {
                  await ref.read(syncMetadataDaoProvider).set('couple_skipped', 'true');
                  ref.invalidate(coupleSkippedProvider);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
