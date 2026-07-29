import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/note_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../notes/domain/note.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({super.key, required this.note});

  final Note note;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  late Note _currentNote;
  bool _isEditMode = false;
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedTag;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    Future.microtask(_loadTags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags = await ref.read(noteRepositoryProvider).getTags('note');
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load note tags: ${AppError.from(error, stackTrace).message}',
      );
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _titleController.text = _currentNote.title;
      _contentController.text = _currentNote.content;
      _selectedTag = _currentNote.tag;
    });
  }

  void _exitEditMode() {
    setState(() => _isEditMode = false);
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
      final updatedNote = _currentNote.copyWith(
        title: title,
        content: _contentController.text.trim(),
        tag: _selectedTag,
      );

      final result = await ref
          .read(noteRepositoryProvider)
          .updateNote(updatedNote);
      if (!mounted) return;

      setState(() {
        _currentNote = result;
        _isEditMode = false;
      });
      ref.invalidate(notesListProvider);
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

  Future<void> _deleteNote() async {
    final theme = context.archivumTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.popover,
        title: Text(
          'Delete Note',
          style: TextStyle(color: theme.popoverForeground),
        ),
        content: Text(
          'Delete this note? This action cannot be undone.',
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
      await ref.read(noteRepositoryProvider).deleteNote(_currentNote.id!);
      ref.invalidate(notesListProvider);
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

  Future<void> _showAddTagDialog() async {
    final theme = context.archivumTheme;
    final tagController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.popover,
        title: Text(
          'Add Tag',
          style: TextStyle(color: theme.popoverForeground),
        ),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(hintText: 'Tag name'),
          autofocus: true,
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

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
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
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final accent = theme.primary;

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
        title: Text(_isEditMode ? 'Edit Note' : _currentNote.title),
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
                  onPressed: _deleteNote,
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
            _HeroCard(
              accent: accent,
              icon: Icons.edit_note_rounded,
              eyebrow: _isEditMode ? 'Note editor' : 'Note',
              title: _currentNote.title,
              subtitle: _isEditMode
                  ? 'Refine the title, content, and tag in one place.'
                  : (_currentNote.content.trim().isEmpty
                        ? 'No content yet.'
                        : _currentNote.content.trim()),
              chips: [
                if ((_currentNote.tag ?? '').isNotEmpty)
                  _HeroChip(label: _currentNote.tag!, accent: accent),
                _HeroChip(
                  label: _formatDate(_currentNote.createdAt),
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
          title: 'Content',
          accent: accent,
          child: Text(
            _currentNote.content.trim().isEmpty
                ? 'No content yet. Tap edit to add content.'
                : _currentNote.content,
            style: TextStyle(
              color: _currentNote.content.trim().isEmpty
                  ? theme.mutedForeground
                  : theme.foreground,
              fontSize: 15,
              height: 1.7,
              fontStyle: _currentNote.content.trim().isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _deleteNote,
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
          label: const Text('Delete Note'),
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
          _FieldLabel(label: 'Title', accent: accent),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Enter title'),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Tag', accent: accent),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                _ChoiceChip(
                  label: tag,
                  selected: _selectedTag == tag,
                  accent: accent,
                  onTap: () => setState(() {
                    _selectedTag = _selectedTag == tag ? null : tag;
                  }),
                ),
              _AddChip(accent: accent, onTap: _showAddTagDialog),
            ],
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Content', accent: accent),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Start writing your note',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String title;
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
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
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
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : theme.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : theme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : theme.mutedForeground,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Add tag',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
