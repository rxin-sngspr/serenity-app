import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/components/serenity_card.dart';
import '../../../core/components/sync_status_indicator.dart';
import '../widgets/theme_picker.dart';
import '../providers/me_provider.dart';
import '../../couple/providers/couple_provider.dart';
import '../../auth/screens/couple_linking_screen.dart';
import '../../couple/screens/couple_settings_screen.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (file != null && mounted) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destPath = '${dir.path}/profile_$timestamp.jpg';
        final destFile = File(destPath);
        await destFile.writeAsBytes(await file.readAsBytes());
        final dao = ref.read(settingsDaoProvider);
        await dao.set('profile_photo_path', destPath);
        ref.invalidate(profilePhotoPathProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: $e')),
        );
      }
    }
  }

  void _showPhotoPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Serenity',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A private space for your relationship story.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Built with \u2665',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final current = ref.read(userNameProvider).valueOrNull ?? '';
    _nameController.text = current;
    final name = await _showEditDialog(
      context: context,
      title: 'Your Name',
      controller: _nameController,
    );
    if (name != null && mounted) {
      final dao = ref.read(settingsDaoProvider);
      await dao.set('display_name', name);
      ref.invalidate(userNameProvider);
    }
  }

  Future<void> _editPartnerName() async {
    final current = ref.read(partnerNameProvider).valueOrNull ?? '';
    _partnerController.text = current;
    final name = await _showEditDialog(
      context: context,
      title: 'Partner Name',
      controller: _partnerController,
    );
    if (name != null && mounted) {
      final dao = ref.read(settingsDaoProvider);
      await dao.set('partner_name', name);
      ref.invalidate(partnerNameProvider);
    }
  }

  Future<String?> _showEditDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name...',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = ref.watch(brightnessProvider);
    final nameAsync = ref.watch(userNameProvider);
    final partnerAsync = ref.watch(partnerNameProvider);
    final photoAsync = ref.watch(profilePhotoPathProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: const [
          SyncStatusIndicator(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Photo
          SerenityCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showPhotoPicker(context),
                  child: photoAsync.when(
                    data: (path) => CircleAvatar(
                      radius: 38,
                      backgroundColor: theme.colorScheme.primary,
                      child: path != null && path.isNotEmpty
                        ? CircleAvatar(
                            radius: 36,
                            backgroundImage: FileImage(File(path)),
                          )
                        : CircleAvatar(
                            radius: 36,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(LucideIcons.heart, size: 32,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                    ),
                    loading: () => CircleAvatar(
                      radius: 38,
                      backgroundColor: theme.colorScheme.primary,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nameAsync.valueOrNull ?? 'You',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    photoAsync.when(
                      data: (path) => CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: path != null && path.isNotEmpty
                          ? CircleAvatar(
                              radius: 26,
                              backgroundImage: FileImage(File(path)),
                            )
                          : CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(LucideIcons.heart, size: 24,
                                  color: theme.colorScheme.onPrimaryContainer),
                            ),
                      ),
                      loading: () => CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      error: (_, _) => CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(LucideIcons.heart, size: 24,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameAsync.valueOrNull ?? 'You',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (partnerAsync.valueOrNull != null)
                            Text(
                              '${partnerAsync.valueOrNull} \u2665',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _editName,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit Name'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _editPartnerName,
                  icon: const Icon(LucideIcons.heart, size: 16),
                  label: const Text('Partner Name'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Partner / Couple
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )),
                const SizedBox(height: 8),
                ref.watch(coupleStatusProvider).when(
                  data: (couple) {
                    if (couple == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Not connected to a partner yet.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(builder: (_) => const CoupleLinkingScreen()),
                            ),
                            icon: const Icon(LucideIcons.link, size: 16),
                            label: const Text('Connect Partner'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      );
                    }
                    return OutlinedButton.icon(
                      onPressed: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const CoupleSettingsScreen()),
                      ),
                      icon: const Icon(LucideIcons.heart, size: 16),
                      label: const Text('Couple Settings'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 20, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── PARTNER'S RECENT ANSWERS ──
          _PartnerAnswersSection(),
          const SizedBox(height: 16),

          // Theme
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )),
                const SizedBox(height: 8),
                const ThemePicker(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dark Mode',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        )),
                    Switch(
                      value: brightness == Brightness.dark,
                      onChanged: (v) async {
                        final b = v ? Brightness.dark : Brightness.light;
                        ref.read(brightnessProvider.notifier).state = b;
                        final dao = ref.read(settingsDaoProvider);
                        await dao.set('brightness',
                            b == Brightness.dark ? 'dark' : 'light');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.download),
                  title: Text('Export Database',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      )),
                  subtitle: Text('Save a copy of your data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  onTap: () async {
                    try {
                      final dir = await getApplicationDocumentsDirectory();
                      final file = File('${dir.path}/serenity.sqlite');
                      if (await file.exists()) {
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Serenity database export',
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No database found yet')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About
          SerenityCard(
            child: InkWell(
              onTap: () => _showAboutSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('About',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        )),
                    Icon(LucideIcons.chevronRight, size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerAnswersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnerAnswers = ref.watch(partnerAnswersProvider);
    final partnerName = ref.watch(partnerNameProvider).valueOrNull ?? 'Partner';

    return SerenityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messageCircle, size: 16,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text("$partnerName's Answers",
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          partnerAnswers.when(
            data: (answers) {
              if (answers.isEmpty) {
                return Text(
                  'No answers from $partnerName yet. Answers sync when your partner reflects.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: answers.take(5).map((answer) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(answer.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              )),
                          const Spacer(),
                          Text(
                            _formatDate(answer.dateAnswered),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        answer.answerText,
                        style: TextStyle(fontFamily: 'Cormorant Garamond',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (answers.last != answer)
                        Divider(height: 16,
                            color: theme.colorScheme.outline.withValues(alpha: 0.24)),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
