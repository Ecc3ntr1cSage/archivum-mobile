import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/index_item.dart';
import '../../../core/providers/index_repository_provider.dart';

class AddIndexPage extends ConsumerStatefulWidget {
  const AddIndexPage({super.key});

  @override
  ConsumerState<AddIndexPage> createState() => _AddIndexPageState();
}

class _AddIndexPageState extends ConsumerState<AddIndexPage> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _itemControllers = [
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
    });
  }

  Future<void> _saveIndex() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    // Collect non-empty items
    final items = _itemControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .map((text) => IndexItem(item: text))
        .toList();

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(indexRepositoryProvider);
      await repository.createIndex(IndexEntry(title: title, items: items));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save index: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha:0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? surfaceColor : Colors.grey[200],
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        title: Text(
          'Create New Index',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: borderColor,
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // List Title Input
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

                // Dynamic List Section
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: clr.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_itemControllers.length} Items',
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

                // List Items
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _itemControllers.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _itemControllers.removeAt(oldIndex);
                      _itemControllers.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      key: ValueKey(_itemControllers[index]),
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _itemControllers[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Add item...',
                                        hintStyle: TextStyle(
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _removeItem(index),
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
                  onPressed: _addItem,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: clr.secondary.withValues(alpha:0.3), width: 2, style: BorderStyle.solid),
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

          // Fixed Bottom Actions
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
                    bgColor.withValues(alpha:0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveIndex,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clr.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: clr.primary.withValues(alpha:0.4),
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
                      _isSaving ? 'Saving...' : 'Save List',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
