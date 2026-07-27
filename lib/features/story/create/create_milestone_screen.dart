import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/palette.dart';
import '../providers/timeline_provider.dart';

class CreateMilestoneScreen extends ConsumerStatefulWidget {
  final int? milestoneId;

  const CreateMilestoneScreen({super.key, this.milestoneId});

  @override
  ConsumerState<CreateMilestoneScreen> createState() =>
      _CreateMilestoneScreenState();
}

class _CreateMilestoneScreenState
    extends ConsumerState<CreateMilestoneScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedIcon = 'star';
  Color _selectedColor = const Color(0xFFE8A87C);
  bool _saving = false;
  bool _titleError = false;
  bool _loading = true;

  // Track original values for unsaved-changes comparison
  String _loadedTitle = '';
  String _loadedDescription = '';
  DateTime _loadedDate = DateTime.now();
  String _loadedIcon = 'star';
  Color _loadedColor = const Color(0xFFE8A87C);

  bool get _isEditing => widget.milestoneId != null;

  bool get _hasUnsavedChanges =>
      _titleController.text.trim() != _loadedTitle ||
      _descriptionController.text.trim() != _loadedDescription ||
      _selectedDate != _loadedDate ||
      _selectedIcon != _loadedIcon ||
      _selectedColor != _loadedColor;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadMilestone();
    } else {
      // Create mode has nothing to load, show the form immediately.
      _loading = false;
    }
  }

  Future<void> _loadMilestone() async {
    setState(() => _loading = true);
    try {
      final dao = ref.read(milestonesDaoProvider);
      final milestone = await dao.getMilestoneById(widget.milestoneId!);
      if (milestone != null && mounted) {
        _titleController.text = milestone.title;
        _descriptionController.text = milestone.description ?? '';
        _selectedDate = milestone.date;
        _selectedIcon = milestone.icon ?? 'star';

        if (milestone.color != null) {
          _selectedColor = Color(
            int.parse(milestone.color!.substring(1), radix: 16) | 0xFF000000,
          );
        }

        // Track original values for unsaved-changes detection
        _loadedTitle = milestone.title;
        _loadedDescription = milestone.description ?? '';
        _loadedDate = milestone.date;
        _loadedIcon = milestone.icon ?? 'star';
        _loadedColor = _selectedColor;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load milestone: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _iconOptions = [
    'favorite', 'star', 'celebration', 'church',
    'home', 'flight', 'work', 'school', 'pets', 'diamond',
  ];

  // Theme-aware color options using palette colors
  static final _colorOptions = [
    const Color(0xFFE8A87C),
    const Color(0xFFF4A261),
    const Color(0xFFE76F51),
    const Color(0xFF2A9D8F),
    const Color(0xFF264653),
    const Color(0xFFE9C46A),
    const Color(0xFFA8DADC),
    const Color(0xFFCDB4DB),
    WarmRosePalette.primary,
    SagePalette.primary,
    OceanPalette.primary,
    TerracottaPalette.primary,
    LavenderPalette.primary,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'favorite': return LucideIcons.heart;
      case 'star': return LucideIcons.star;
      case 'celebration': return LucideIcons.sparkles;
      case 'church': return LucideIcons.circle;
      case 'home': return LucideIcons.home;
      case 'flight': return LucideIcons.plane;
      case 'work': return LucideIcons.briefcase;
      case 'school': return LucideIcons.graduationCap;
      case 'pets': return LucideIcons.footprints;
      case 'diamond': return LucideIcons.gem;
      default: return LucideIcons.star;
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _saving) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _colorHex() =>
      '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    setState(() => _saving = true);

    try {
      final dao = ref.read(milestonesDaoProvider);

      if (_isEditing) {
        await dao.updateMilestone(
          MilestonesCompanion(
            id: Value(widget.milestoneId!),
            title: Value(title),
            description: Value(_descriptionController.text.trim()),
            date: Value(_selectedDate),
            icon: Value(_selectedIcon),
            color: Value(_colorHex()),
            createdBy: Value(Supabase.instance.client.auth.currentUser?.id),
          ),
        );
      } else {
        await dao.createMilestone(
          MilestonesCompanion(
            title: Value(title),
            description: Value(_descriptionController.text.trim()),
            date: Value(_selectedDate),
            icon: Value(_selectedIcon),
            color: Value(_colorHex()),
            createdBy: Value(Supabase.instance.client.auth.currentUser?.id),
          ),
        );
      }

      if (mounted) {
        ref.invalidate(timelineProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasUnsavedChanges || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Milestone' : 'New Milestone'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'What happened?',
                  errorText: _titleError ? 'Title is required' : null,
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_titleError && _titleController.text.trim().isNotEmpty) {
                    setState(() => _titleError = false);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(_formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Icon', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.map((icon) {
                  final selected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withAlpha(40)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _iconData(icon),
                        color: selected ? _selectedColor : null,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Color', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((color) {
                  final selected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? Border.all(
                                color: theme.colorScheme.primary, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
