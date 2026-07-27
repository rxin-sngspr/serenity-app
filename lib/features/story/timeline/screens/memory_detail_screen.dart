import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/components/serenity_card.dart';
import '../../../../core/components/category_badge.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  final int memoryId;

  const MemoryDetailScreen({super.key, required this.memoryId});

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  Memory? _memory;
  List<Tag> _tags = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dao = ref.read(memoriesDaoProvider);
      final memory = await dao.getMemoryById(widget.memoryId);

      if (memory != null) {
        final tagsDao = ref.read(tagsDaoProvider);
        final tags = await tagsDao.getTagsForMemory(widget.memoryId);
        if (mounted) {
          setState(() {
            _memory = memory;
            _tags = tags;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Memory not found';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load memory: $e';
          _loading = false;
        });
      }
    }
  }

  void _share() {
    if (_memory == null) return;
    final text = '${_memory!.title}\n\n${_memory!.body}';
    Share.share(text);
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year} at $h:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _memory?.title ?? 'Memory',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_memory != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.pencil),
              onPressed: () => context.pushNamed(
                'create-memory',
                extra: widget.memoryId,
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(LucideIcons.share2),
              onPressed: _share,
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.frown,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final memory = _memory!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date display (Cormorant Garamond italic 18px)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _formatDate(memory.date),
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Category badge
          if (memory.type.isNotEmpty && memory.type != 'memory')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CategoryBadge(label: memory.type),
            ),

          // Full body text in SerenityCard
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  memory.title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Body
                Text(
                  memory.body,
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 17,
                    height: 26 / 17,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                // Tags
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((tag) {
                      final hex = tag.color;
                      final bgColor = hex != null
                          ? Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000)
                          : theme.colorScheme.primary;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
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
                ],
              ],
            ),
          ),

          // Created at timestamp
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Written ${_formatDateFull(memory.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
