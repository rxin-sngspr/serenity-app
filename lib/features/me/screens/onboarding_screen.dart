import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/components/serenity_header.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final partner = _partnerController.text.trim();

    final dao = ref.read(settingsDaoProvider);
    await dao.set('display_name', name);
    if (partner.isNotEmpty) {
      await dao.set('partner_name', partner);
    }

    ref.read(onboardedProvider.notifier).state = true;
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const SerenityHeader(),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Enter your name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partnerController,
                  decoration: const InputDecoration(
                    labelText: "Partner's name (optional)",
                    hintText: "Enter your partner's name",
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _onStart,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Begin',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
