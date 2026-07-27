import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/components/serenity_header.dart';
import '../../../core/database/database_provider.dart';
import '../../couple/providers/couple_provider.dart';

class CreateCoupleScreen extends ConsumerStatefulWidget {
  const CreateCoupleScreen({super.key});

  @override
  ConsumerState<CreateCoupleScreen> createState() =>
      _CreateCoupleScreenState();
}

class _CreateCoupleScreenState extends ConsumerState<CreateCoupleScreen>
    with SingleTickerProviderStateMixin {
  String? _inviteCode;
  bool _isGenerating = true;
  String? _error;
  bool _copied = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _generateCode();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final result = await ref.read(coupleServiceProvider).createInviteCode();
      final code = result['code'] as String;
      final coupleId = result['id'] as String?;
      if (coupleId != null) {
        await ref.read(syncMetadataDaoProvider).set('couple_id', coupleId);
      }
      if (!mounted) return;
      setState(() {
        _inviteCode = code;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isGenerating = false;
      });
    }
  }

  void _copyCode() {
    if (_inviteCode == null) return;

    Clipboard.setData(ClipboardData(text: _inviteCode!));
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });

    final snackTheme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        backgroundColor: snackTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
              const SizedBox(height: 48),
              Text(
                'Share this code with your partner',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isGenerating)
                _buildLoadingState()
              else if (_error != null)
                _buildErrorState()
              else
                _buildCodeDisplay(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    ref.invalidate(coupleStatusProvider);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 12),
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

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          LucideIcons.alertCircle,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _generateCode,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay() {
    final theme = Theme.of(context);

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _inviteCode!,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 8,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _copyCode,
                  icon: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    color: _copied
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Waiting for partner to connect...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
