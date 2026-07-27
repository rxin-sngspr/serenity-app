import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/components/serenity_card.dart';
import '../providers/timeline_provider.dart';

class CreateMemoryScreen extends ConsumerStatefulWidget {
  final int? memoryId;

  const CreateMemoryScreen({super.key, this.memoryId});

  @override
  ConsumerState<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

class _CreateMemoryScreenState extends ConsumerState<CreateMemoryScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  final _tagFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  final List<String> _tags = [];
  bool _saving = false;
  bool _titleError = false;
  bool _loading = false;

  // Edit mode tracking
  bool get _isEditing => widget.memoryId != null;
  String _loadedTitle = '';
  String _loadedBody = '';
  DateTime _loadedDate = DateTime.now();
  List<String> _loadedTags = [];
  String? _loadedPhotoPath;

  bool get _hasUnsavedChanges {
    if (_isEditing) {
      return _titleController.text.trim() != _loadedTitle ||
          _bodyController.text.trim() != _loadedBody ||
          _selectedDate != _loadedDate ||
          _imageFile?.path != _loadedPhotoPath ||
          _tags.toSet() != _loadedTags.toSet();
    }
    return _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _imageFile != null ||
        _tags.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadMemory();
    }
  }

  Future<void> _loadMemory() async {
    setState(() => _loading = true);
    try {
      final dao = ref.read(memoriesDaoProvider);
      final memory = await dao.getMemoryById(widget.memoryId!);
      if (memory != null && mounted) {
        _titleController.text = memory.title;
        _bodyController.text = memory.body;
        _selectedDate = memory.date;

        // Load photos
        final mediaList = await dao.getMediaForMemory(widget.memoryId!);
        if (mediaList.isNotEmpty) {
          final file = File(mediaList.first.path);
          if (file.existsSync()) {
            _imageFile = file;
            _loadedPhotoPath = file.path;
          }
        }

        // Load tags
        final tagsDao = ref.read(tagsDaoProvider);
        final tags = await tagsDao.getTagsForMemory(widget.memoryId!);
        _tags.addAll(tags.map((t) => t.name));

        // Track loaded state for unsaved-changes comparison
        _loadedTitle = memory.title;
        _loadedBody = memory.body;
        _loadedDate = memory.date;
        _loadedTags = List.from(_tags);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load memory: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'memory_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${dir.path}/$fileName';
      final bytes = await photo.readAsBytes();
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(bytes);
      setState(() => _imageFile = savedFile);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
      _tagFocusNode.requestFocus();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);

      if (_isEditing) {
        final memoryId = widget.memoryId!;

        // Update memory record
        await db.update(db.memories).replace(
          MemoriesCompanion(
            id: Value(memoryId),
            title: Value(title),
            body: Value(_bodyController.text.trim()),
            date: Value(_selectedDate),
            type: const Value('memory'),
            createdBy: Value(Supabase.instance.client.auth.currentUser?.id),
          ),
        );

        // Handle photo changes
        if (_imageFile != null) {
          if (_imageFile!.path != _loadedPhotoPath) {
            // Photo changed — delete old media, save new
            await (db.delete(db.memoryMedia)
              ..where((t) => t.memoryId.equals(memoryId))).go();
            await db.into(db.memoryMedia).insert(
              MemoryMediaCompanion(
                memoryId: Value(memoryId),
                mimeType: Value('image/jpeg'),
                path: Value(_imageFile!.path),
              ),
            );
          }
        } else if (_loadedPhotoPath != null) {
          // User removed the photo
          await (db.delete(db.memoryMedia)
            ..where((t) => t.memoryId.equals(memoryId))).go();
        }

        // Clear and re-assign tags
        final tagsDao = ref.read(tagsDaoProvider);
        await tagsDao.removeAllAssignmentsForMemory(memoryId);
        for (final tagName in _tags) {
          final tag = await tagsDao.getOrCreateTag(tagName);
          await tagsDao.assignTag(tag.id, memoryId);
        }
      } else {
        // Create new memory
        final memoryId = await db.into(db.memories).insert(
          MemoriesCompanion(
            title: Value(title),
            body: Value(_bodyController.text.trim()),
            date: Value(_selectedDate),
            type: const Value('memory'),
            createdBy: Value(Supabase.instance.client.auth.currentUser?.id),
          ),
        );

        // Save photo
        if (_imageFile != null) {
          await db.into(db.memoryMedia).insert(
            MemoryMediaCompanion(
              memoryId: Value(memoryId),
              mimeType: Value('image/jpeg'),
              path: Value(_imageFile!.path),
            ),
          );
        }

        // Save tags
        final tagsDao = ref.read(tagsDaoProvider);
        for (final tagName in _tags) {
          final tag = await tagsDao.getOrCreateTag(tagName);
          await tagsDao.assignTag(tag.id, memoryId);
        }
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
          title: Text(_isEditing ? 'Edit Memory' : 'New Memory'),
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
              SerenityCard(
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
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Story',
                        hintText: 'Write down the details...',
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 6,
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Photo
              SerenityCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photo',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(_imageFile!, width: double.infinity, height: 200, fit: BoxFit.cover),
                            Positioned(
                              top: 8, right: 8,
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black38,
                                ),
                                onPressed: () => setState(() => _imageFile = null),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(LucideIcons.image),
                      label: Text(_imageFile == null ? 'Add Photo' : 'Change Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tags
              SerenityCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tags', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            focusNode: _tagFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Add a tag...',
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.plusCircle),
                          onPressed: _addTag,
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(LucideIcons.x, size: 16),
                            onDeleted: () => _removeTag(tag),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
