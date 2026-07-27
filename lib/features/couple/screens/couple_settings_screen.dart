import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/components/serenity_card.dart';
import '../../couple/providers/couple_provider.dart';

/// Settings screen for couple management.
///
/// Displays partner info, invite code, unlink action, and sign-out.
class CoupleSettingsScreen extends ConsumerStatefulWidget {
  const CoupleSettingsScreen({super.key});

  @override
  ConsumerState<CoupleSettingsScreen> createState() =>
      _CoupleSettingsScreenState();
}

class _CoupleSettingsScreenState extends ConsumerState<CoupleSettingsScreen> {
  bool _isRegenerating = false;
  bool _isUnlinking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coupleAsync = ref.watch(coupleStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Settings'),
      ),
      body: coupleAsync.when(
        data: (couple) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Partner info card ----
            SerenityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.heart, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Your Partner',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    couple?['partner_name'] as String? ?? 'Not linked to a partner yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Invite code section ----
            SerenityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.qrCode,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Invite Code',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      couple?['invite_code'] as String? ?? '--------',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isRegenerating ? null : _regenerateInviteCode,
                      icon: _isRegenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(
                        _isRegenerating
                            ? 'Regenerating...'
                            : 'Regenerate Code',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Danger zone ----
            SerenityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.shieldAlert,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Text(
                        'Danger Zone',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlinking removes the connection with your partner. '
                    'Your local data stays. Your partner keeps their copy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      onPressed: _isUnlinking ? null : _unlink,
                      icon: _isUnlinking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.unlink, size: 16),
                      label: Text(_isUnlinking ? 'Unlinking...' : 'Unlink'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Sign out ----
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(LucideIcons.logOut),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not load couple data.\n$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _regenerateInviteCode() async {
    setState(() => _isRegenerating = true);
    try {
      await ref.read(coupleServiceProvider).createInviteCode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New invite code generated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate: $e')),
      );
    } finally {
      if (mounted)     setState(() => _isRegenerating = false);
    }
  }

  Future<void> _unlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink from partner?'),
        content: const Text(
          'Your local data stays. Your partner will still have their copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUnlinking = true);
    try {
      await ref.read(coupleServiceProvider).unlink();
      // Clear local sync metadata so the sync engine stops
      await ref.read(syncMetadataDaoProvider).remove('couple_id');
      if (!mounted) return;
      ref.invalidate(coupleStatusProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlinked successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlink: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUnlinking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider).signOut();
    if (!mounted) return;
    context.go('/onboarding');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------


}
