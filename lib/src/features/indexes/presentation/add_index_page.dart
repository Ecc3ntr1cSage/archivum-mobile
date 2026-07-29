import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/index_repository_provider.dart';
import '../../snippets/presentation/almanac_style.dart';
import '../domain/index_item.dart';

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
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _itemControllers.add(TextEditingController()));
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
      if (_itemControllers.isEmpty) {
        _itemControllers.add(TextEditingController());
      }
    });
  }

  Future<void> _saveIndex() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    final items = _itemControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .map((text) => IndexItem(item: text))
        .toList();

    setState(() => _isSaving = true);
    try {
      await ref
          .read(indexRepositoryProvider)
          .createIndex(IndexEntry(title: title, items: items));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save index: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlmanacColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AlmanacBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AlmanacTopBar(
                  title: 'NEW INDEX',
                  subtitle: 'Build checklist memory',
                  leading: AlmanacIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 122),
                    children: [
                      AlmanacPanel(
                        borderColor: AlmanacColors.tertiary.withValues(
                          alpha: 0.34,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('INDEX TITLE'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: AlmanacColors.foreground,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: almanacInputDecoration(
                                'e.g. Weekly groceries',
                                prefixIcon: Icons.dataset_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AlmanacPanel(
                        borderColor: AlmanacColors.outline.withValues(
                          alpha: 0.44,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(child: _FieldLabel('ITEMS')),
                                _CountBadge(count: _itemControllers.length),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _itemControllers.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _itemControllers.removeAt(
                                    oldIndex,
                                  );
                                  _itemControllers.insert(newIndex, item);
                                });
                              },
                              proxyDecorator: (child, index, animation) {
                                return Material(
                                  color: Colors.transparent,
                                  child: FadeTransition(
                                    opacity: animation.drive(
                                      Tween(begin: 0.84, end: 1.0),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              itemBuilder: (context, index) {
                                return _IndexItemInput(
                                  key: ValueKey(_itemControllers[index]),
                                  controller: _itemControllers[index],
                                  index: index,
                                  canRemove: _itemControllers.length > 1,
                                  onRemove: () => _removeItem(index),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              onPressed: _addItem,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AlmanacColors.secondary,
                                side: BorderSide(
                                  color: AlmanacColors.secondary.withValues(
                                    alpha: 0.36,
                                  ),
                                  width: 1.5,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add item'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveIndex,
                style: almanacCommitButtonStyle(AlmanacColors.tertiary),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Commit index'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexItemInput extends StatelessWidget {
  const _IndexItemInput({
    required this.controller,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    super.key,
  });

  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 42,
              height: 50,
              decoration: BoxDecoration(
                color: AlmanacColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AlmanacColors.outline),
              ),
              child: const Icon(
                Icons.drag_indicator_rounded,
                color: AlmanacColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: almanacInputDecoration('Add item...'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: canRemove ? onRemove : null,
            color: AlmanacColors.muted,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AlmanacColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count ITEMS',
        style: const TextStyle(
          color: AlmanacColors.tertiary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AlmanacColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
