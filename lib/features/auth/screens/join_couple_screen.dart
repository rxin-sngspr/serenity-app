import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/components/serenity_header.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/sync/sync_provider.dart';
import '../../couple/providers/couple_provider.dart';

class JoinCoupleScreen extends ConsumerStatefulWidget {
  const JoinCoupleScreen({super.key});

  @override
  ConsumerState<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends ConsumerState<JoinCoupleScreen> {
  static const int _codeLength = 6;

  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _codeLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onCharChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(0, 1);
    }

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (index == _codeLength - 1 && value.isNotEmpty && _code.length == _codeLength) {
      _submitCode();
    }
  }


  Future<void> _submitCode() async {
    final code = _code;
    if (code.length != _codeLength) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final couple = await ref.read(coupleServiceProvider).joinWithCode(code);

      // Save couple_id so the sync engine can push/pull
      final coupleId = couple['id'] as String?;
      if (coupleId != null) {
        await ref.read(syncMetadataDaoProvider).set('couple_id', coupleId);
      }

      if (!mounted) return;

      final joinTheme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connected with your partner'),
          backgroundColor: joinTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Trigger sync to push existing local data and pull partner's
      ref.read(syncStateProvider.notifier).triggerSync();

      ref.invalidate(coupleStatusProvider);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),
                const SerenityHeader(),
                const SizedBox(height: 48),
                Text(
                  "Enter your partner's code",
                  style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildCodeInput(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _clearCode,
                    child: Text(
                      'Try again',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 48),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                            await ref.read(syncMetadataDaoProvider).set('couple_skipped', 'true');
                            ref.invalidate(coupleSkippedProvider);
                            if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
      ),
    );
  }

  Widget _buildCodeInput() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_codeLength, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.24),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.24),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            onChanged: (value) => _onCharChanged(index, value),
            onFieldSubmitted: (value) {
              if (index == _codeLength - 1 && value.isNotEmpty) {
                _submitCode();
              }
            },
          ),
        );
      }),
    );
  }
}
