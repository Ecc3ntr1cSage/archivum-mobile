import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/note_repository_provider.dart';
import '../../snippets/presentation/almanac_style.dart';
import '../domain/note.dart';

class AddNotePage extends ConsumerStatefulWidget {
  const AddNotePage({super.key});

  @override
  ConsumerState<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends ConsumerState<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<String> _tags = [];
  String? _selectedTag;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTags);
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags = await ref.read(noteRepositoryProvider).getTags('note');
      if (mounted) setState(() => _tags = tags);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load note tags: ${AppError.from(error, stackTrace).message}',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AlmanacColors.surfaceHigh,
        title: const Text('Add note tag'),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: almanacInputDecoration('Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = tagController.text.trim();
              if (text.isEmpty) return;
              try {
                await ref.read(noteRepositoryProvider).addTag(text, 'note');
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {
                  if (!_tags.contains(text)) _tags.add(text);
                  _selectedTag = text;
                });
              } catch (error, stackTrace) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to add tag: ${AppError.from(error, stackTrace).message}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    tagController.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(noteRepositoryProvider)
          .createNote(Note(title: title, content: content, tag: _selectedTag));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save note: ${AppError.from(error, stackTrace).message}',
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
                  title: 'NEW NOTE',
                  subtitle: 'Capture observation',
                  leading: AlmanacIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    children: [
                      AlmanacPanel(
                        borderColor: AlmanacColors.primary.withValues(
                          alpha: 0.32,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('TITLE'),
                            TextField(
                              controller: _titleController,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: AlmanacColors.foreground,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Name this memory...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
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
                                const Expanded(child: _FieldLabel('TAGS')),
                                IconButton(
                                  onPressed: _showAddTagDialog,
                                  color: AlmanacColors.secondary,
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_tags.isEmpty)
                              const Text(
                                'No tags linked yet.',
                                style: TextStyle(color: AlmanacColors.muted),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final tag in _tags)
                                    _TagChip(
                                      label: tag,
                                      selected: _selectedTag == tag,
                                      onTap: () => setState(
                                        () => _selectedTag = _selectedTag == tag
                                            ? null
                                            : tag,
                                      ),
                                    ),
                                ],
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
                            const _FieldLabel('CONTENT'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contentController,
                              maxLines: null,
                              minLines: 12,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                color: AlmanacColors.foreground,
                                fontSize: 17,
                                height: 1.55,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Start typing your note...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
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
                onPressed: _isSaving ? null : _saveNote,
                style: almanacCommitButtonStyle(AlmanacColors.primary),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Commit note'),
              ),
            ),
          ),
        ],
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

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AlmanacColors.primary.withValues(alpha: 0.16)
              : AlmanacColors.surfaceHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AlmanacColors.primary : AlmanacColors.outline,
          ),
        ),
        child: Text(
          '#$label',
          style: TextStyle(
            color: selected ? AlmanacColors.primarySoft : AlmanacColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
