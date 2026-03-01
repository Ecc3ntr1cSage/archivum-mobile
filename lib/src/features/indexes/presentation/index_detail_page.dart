import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/index_item.dart';
import '../../../core/providers/index_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';

/// Helper class to manage editable item state in edit mode
class _EditableItem {
  final String? id;
  final TextEditingController controller;
  int? status;

  _EditableItem({this.id, required this.controller, this.status});

  void dispose() => controller.dispose();
}

class IndexDetailPage extends ConsumerStatefulWidget {
  final IndexEntry index;

  const IndexDetailPage({super.key, required this.index});

  @override
  ConsumerState<IndexDetailPage> createState() => _IndexDetailPageState();
}

class _IndexDetailPageState extends ConsumerState<IndexDetailPage> {
  late IndexEntry _currentIndex;
  bool _isEditMode = false;
  bool _isSaving = false;

  // Edit mode state
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
    for (var item in _editItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _titleController.text = _currentIndex.title;
      // Dispose old edit items
      for (var item in _editItems) {
        item.dispose();
      }
      _editItems = _currentIndex.items.map((item) => _EditableItem(
        id: item.id,
        controller: TextEditingController(text: item.item),
        status: item.status,
      )).toList();
      // Add an empty item if list is empty
      if (_editItems.isEmpty) {
        _editItems.add(_EditableItem(controller: TextEditingController()));
      }
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
    });
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
    });
  }

  void _toggleEditItemStatus(int index) {
    setState(() {
      final current = _editItems[index].status ?? 0;
      _editItems[index].status = current == 1 ? 0 : 1;
    });
  }

  Future<void> _toggleViewItemStatus(IndexItem item) async {
    if (item.id == null) return;
    final newStatus = item.isChecked ? 0 : 1;
    try {
      final repo = ref.read(indexRepositoryProvider);
      await repo.updateItemStatus(item.id!, newStatus);
      setState(() {
        final idx = _currentIndex.items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          final updatedItems = List<IndexItem>.from(_currentIndex.items);
          updatedItems[idx] = item.copyWith(status: () => newStatus);
          _currentIndex = _currentIndex.copyWith(items: updatedItems);
        }
      });
      ref.invalidate(indexesListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _saveEdit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build items from edit state, filtering out empty text
      final items = _editItems
          .where((e) => e.controller.text.trim().isNotEmpty)
          .map((e) => IndexItem(
                id: e.id,
                indexId: _currentIndex.id,
                item: e.controller.text.trim(),
                status: e.status,
              ))
          .toList();

      final updatedEntry = IndexEntry(
        id: _currentIndex.id,
        userId: _currentIndex.userId,
        title: title,
        items: items,
      );

      final repo = ref.read(indexRepositoryProvider);
      final result = await repo.updateIndex(updatedEntry);

      if (!mounted) return;
      setState(() {
        _currentIndex = result;
        _isEditMode = false;
      });
      ref.invalidate(indexesListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteIndex() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Index'),
        content: const Text(
            'Are you sure you want to delete this index? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(indexRepositoryProvider);
      await repo.deleteIndex(_currentIndex.id!);
      ref.invalidate(indexesListProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;
    final bgColor = isDark ? const Color(0xFF120D17) : const Color(0xFFF7F6F8);
    final surfaceColor = isDark ? const Color(0xFF1E1626) : Colors.white;
    final borderColor = isDark ? const Color(0xFF342A3D) : Colors.grey[200]!;
    const indexColor = Colors.green;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (_isEditMode) {
                _exitEditMode();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? surfaceColor : Colors.grey[200],
              ),
              child: Icon(
                _isEditMode ? Icons.close : Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        title: Text(
          _isEditMode ? 'Edit Index' : _currentIndex.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: _isEditMode
            ? []
            : [
                IconButton(
                  onPressed: _enterEditMode,
                  icon: Icon(Icons.edit_outlined,
                      color: isDark ? Colors.grey[300] : Colors.grey[600]),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.grey[300] : Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'delete') _deleteIndex();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: _isEditMode
          ? _buildEditBody(isDark, clr, bgColor, surfaceColor, borderColor)
          : _buildViewBody(isDark, clr, bgColor, surfaceColor, borderColor, indexColor),
    );
  }

  // ─── VIEW MODE ────────────────────────────────────────────────────────

  Widget _buildViewBody(bool isDark, ColorScheme clr, Color bgColor,
      Color surfaceColor, Color borderColor, Color indexColor) {
    final checkedCount =
        _currentIndex.items.where((i) => i.isChecked).length;
    final totalCount = _currentIndex.items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  indexColor.withOpacity(isDark ? 0.15 : 0.1),
                  indexColor.withOpacity(isDark ? 0.05 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: indexColor.withOpacity(isDark ? 0.2 : 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: indexColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.list_alt,
                          color: indexColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$checkedCount of $totalCount completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          if (_currentIndex.createdAt != null)
                            Text(
                              _formatDate(_currentIndex.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Circular progress
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor:
                                indexColor.withOpacity(isDark ? 0.15 : 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                indexColor),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Items Section Label
          Row(
            children: [
              Text(
                'ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: indexColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: indexColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          if (_currentIndex.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No items yet',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Tap edit to add items',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_currentIndex.items.length, (i) {
              final item = _currentIndex.items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _viewItemTile(
                    item, i, isDark, surfaceColor, borderColor, indexColor),
              );
            }),
        ],
      ),
    );
  }

  Widget _viewItemTile(IndexItem item, int index, bool isDark,
      Color surfaceColor, Color borderColor, Color indexColor) {
    return InkWell(
      onTap: () => _toggleViewItemStatus(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isChecked
                    ? indexColor
                    : Colors.grey.withOpacity(isDark ? 0.2 : 0.15),
                border: Border.all(
                  color: item.isChecked
                      ? indexColor
                      : Colors.grey.withOpacity(isDark ? 0.4 : 0.3),
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            // Item text
            Expanded(
              child: Text(
                item.item,
                style: TextStyle(
                  fontSize: 16,
                  color: item.isChecked
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : (isDark ? Colors.white : Colors.black87),
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey[400],
                ),
              ),
            ),
            // Index number
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EDIT MODE ────────────────────────────────────────────────────────

  Widget _buildEditBody(bool isDark, ColorScheme clr, Color bgColor,
      Color surfaceColor, Color borderColor) {
    const indexColor = Colors.green;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
              left: 16, right: 16, top: 24, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Input
              Text(
                'INDEX TITLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Weekly Groceries',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: clr.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Items header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ITEMS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: clr.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_editItems.length} Items',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: clr.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reorderable items
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _editItems.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _editItems.removeAt(oldIndex);
                    _editItems.insert(newIndex, item);
                  });
                },
                proxyDecorator: (child, index, animation) {
                  return Material(
                      color: Colors.transparent, child: child);
                },
                itemBuilder: (context, index) {
                  final editItem = _editItems[index];
                  final isChecked = (editItem.status ?? 0) == 1;

                  return Padding(
                    key: ValueKey(editItem),
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        // Status check toggle
                        GestureDetector(
                          onTap: () => _toggleEditItemStatus(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked
                                  ? indexColor
                                  : Colors.grey
                                      .withOpacity(isDark ? 0.2 : 0.15),
                              border: Border.all(
                                color: isChecked
                                    ? indexColor
                                    : Colors.grey.withOpacity(
                                        isDark ? 0.4 : 0.3),
                                width: 2,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        // Text field with drag handle
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(
                                      Icons.drag_indicator,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: editItem.controller,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add item...',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        IconButton(
                          onPressed: () => _removeEditItem(index),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.grey[400],
                          splashRadius: 24,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Add Item Button
              OutlinedButton.icon(
                onPressed: _addEditItem,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                      color: clr.secondary.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: clr.secondary,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Add New Item',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Bottom Save Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.9),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: clr.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: clr.primary.withOpacity(0.4),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Created ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
