import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/index_repository_provider.dart';
import '../../../core/providers/almanac_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/index_item.dart';

class _EditableItem {
  _EditableItem({this.id, required this.controller});

  final String? id;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class IndexDetailPage extends ConsumerStatefulWidget {
  const IndexDetailPage({super.key, required this.index});

  final IndexEntry index;

  @override
  ConsumerState<IndexDetailPage> createState() => _IndexDetailPageState();
}

class _IndexDetailPageState extends ConsumerState<IndexDetailPage> {
  late IndexEntry _currentIndex;
  bool _isEditMode = false;
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  List<_EditableItem> _editItems = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final item in _editItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _titleController.text = _currentIndex.title;
      for (final item in _editItems) {
        item.dispose();
      }
      _editItems = _currentIndex.items
          .map(
            (item) => _EditableItem(
              id: item.id,
              controller: TextEditingController(text: item.item),
            ),
          )
          .toList();
      if (_editItems.isEmpty) {
        _editItems.add(_EditableItem(controller: TextEditingController()));
      }
    });
  }

  void _exitEditMode() {
    setState(() => _isEditMode = false);
  }

  void _addEditItem() {
    setState(() {
      _editItems.add(_EditableItem(controller: TextEditingController()));
    });
  }

  void _removeEditItem(int index) {
    setState(() {
      _editItems[index].dispose();
      _editItems.removeAt(index);
      if (_editItems.isEmpty) {
        _editItems.add(_EditableItem(controller: TextEditingController()));
      }
    });
  }

  Future<void> _saveEdit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _editItems
          .where((e) => e.controller.text.trim().isNotEmpty)
          .map(
            (e) => IndexItem(
              id: e.id,
              indexId: _currentIndex.id,
              item: e.controller.text.trim(),
            ),
          )
          .toList();

      final updatedEntry = IndexEntry(
        id: _currentIndex.id,
        userId: _currentIndex.userId,
        title: title,
        items: items,
      );

      final result = await ref
          .read(indexRepositoryProvider)
          .updateIndex(updatedEntry);
      if (!mounted) return;

      setState(() {
        _currentIndex = result;
        _isEditMode = false;
      });
      ref.invalidate(indexesListProvider);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteIndex() async {
    final theme = context.archivumTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.popover,
        title: Text(
          'Delete Index',
          style: TextStyle(color: theme.popoverForeground),
        ),
        content: Text(
          'Delete this index? This action cannot be undone.',
          style: TextStyle(color: theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.destructive,
              foregroundColor: theme.destructiveForeground,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(indexRepositoryProvider).deleteIndex(_currentIndex.id!);
      ref.invalidate(indexesListProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final accent = theme.secondary;
    final totalCount = _currentIndex.items.length;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        leading: IconButton(
          onPressed: () {
            if (_isEditMode) {
              _exitEditMode();
            } else {
              Navigator.pop(context);
            }
          },
          icon: Icon(
            _isEditMode ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
        ),
        title: Text(_isEditMode ? 'Edit Index' : _currentIndex.title),
        actions: _isEditMode
            ? [
                TextButton(
                  onPressed: _exitEditMode,
                  child: const Text('Cancel'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ]
            : [
                IconButton(
                  onPressed: _enterEditMode,
                  icon: Icon(Icons.edit_outlined, color: accent),
                ),
                IconButton(
                  onPressed: _deleteIndex,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.destructive,
                  ),
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IndexHeroCard(
              accent: accent,
              title: _currentIndex.title,
              eyebrow: _isEditMode ? 'Index editor' : 'Index',
              subtitle: _isEditMode
                  ? 'Edit the list items and keep the archive tidy.'
                  : '$totalCount items in this list',
              chips: [
                _HeroChip(label: '$totalCount items', accent: accent),
                _HeroChip(
                  label: _formatDate(_currentIndex.createdAt),
                  accent: accent,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isEditMode)
              _buildEditBody(theme, accent)
            else
              _buildViewBody(theme, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBody(ArchivumTheme theme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Items',
          accent: accent,
          child: _currentIndex.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No items yet. Tap edit to add some.',
                      style: TextStyle(
                        color: theme.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _currentIndex.items.length; i++) ...[
                      _ViewItemTile(item: _currentIndex.items[i], index: i),
                      if (i != _currentIndex.items.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: theme.border),
                        ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _deleteIndex,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.destructive,
            side: BorderSide(color: theme.destructive.withValues(alpha: 0.35)),
            minimumSize: const Size(double.infinity, 0),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete Index'),
        ),
      ],
    );
  }

  Widget _buildEditBody(ArchivumTheme theme, Color accent) {
    return _SectionCard(
      title: 'Edit fields',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Index title', accent: accent),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Weekly groceries'),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Items', accent: accent),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _editItems.length,
            itemBuilder: (context, index) {
              final editItem = _editItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EditItemRow(
                  editItem: editItem,
                  onDelete: () => _removeEditItem(index),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _addEditItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.28)),
              minimumSize: const Size(double.infinity, 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}

class _IndexHeroCard extends StatelessWidget {
  const _IndexHeroCard({
    required this.accent,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.chips,
  });

  final Color accent;
  final String title;
  final String eyebrow;
  final String subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.list_alt_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.mutedForeground,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: title, accent: accent),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _ViewItemTile extends StatelessWidget {
  const _ViewItemTile({required this.item, required this.index});

  final IndexItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            item.item,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '#${index + 1}',
          style: TextStyle(
            color: theme.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EditItemRow extends StatelessWidget {
  const _EditItemRow({required this.editItem, required this.onDelete});

  final _EditableItem editItem;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.muted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: editItem.controller,
              decoration: const InputDecoration(
                hintText: 'Add item',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.mutedForeground,
            ),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
