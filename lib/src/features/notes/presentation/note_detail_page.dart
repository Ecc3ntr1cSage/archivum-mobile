import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notes/domain/note.dart';
import '../../../core/providers/note_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  late Note _currentNote;
  bool _isEditMode = false;
  bool _isSaving = false;

  // Edit mode controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedTag;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    Future.microtask(() => _loadTags());
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
      if (mounted) {
        setState(() {
          _tags = tags;
        });
      }
    } catch (_) {}
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
    setState(() {
      _isEditMode = false;
    });
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
      final updatedNote = _currentNote.copyWith(
        title: title,
        content: _contentController.text.trim(),
        tag: _selectedTag,
      );

      final repo = ref.read(noteRepositoryProvider);
      final result = await repo.updateNote(updatedNote);

      if (!mounted) return;
      setState(() {
        _currentNote = result;
        _isEditMode = false;
      });
      ref.invalidate(notesListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.'),
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
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(_currentNote.id!);
      ref.invalidate(notesListProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
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
              if (text.isNotEmpty) {
                try {
                  await ref.read(noteRepositoryProvider).addTag(text, 'note');
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      if (!_tags.contains(text)) _tags.add(text);
                      _selectedTag = text;
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add tag: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
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
          _isEditMode ? 'Edit Note' : _currentNote.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
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
                    if (value == 'delete') _deleteNote();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
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
          : _buildViewBody(isDark, clr, surfaceColor, borderColor),
    );
  }

  // ─── VIEW MODE ────────────────────────────────────────────────────────

  Widget _buildViewBody(
      bool isDark, ColorScheme clr, Color surfaceColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meta header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  clr.primary.withOpacity(isDark ? 0.15 : 0.1),
                  clr.primary.withOpacity(isDark ? 0.05 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: clr.primary.withOpacity(isDark ? 0.2 : 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: clr.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_note, color: clr.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentNote.tag != null &&
                          _currentNote.tag!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: clr.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _currentNote.tag!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: clr.primary,
                            ),
                          ),
                        ),
                      if (_currentNote.createdAt != null)
                        Text(
                          'Created ${_formatDate(_currentNote.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'TITLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentNote.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Text(
            'CONTENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              _currentNote.content.isEmpty
                  ? 'No content yet. Tap edit to add content.'
                  : _currentNote.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.7,
                color: _currentNote.content.isEmpty
                    ? (isDark ? Colors.grey[600] : Colors.grey[400])
                    : (isDark ? Colors.grey[200] : Colors.grey[700]),
                fontStyle: _currentNote.content.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── EDIT MODE ────────────────────────────────────────────────────────

  Widget _buildEditBody(bool isDark, ColorScheme clr, Color bgColor,
      Color surfaceColor, Color borderColor) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'TITLE',
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
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter title...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              const SizedBox(height: 24),

              // Tags
              Text(
                'TAG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._tags.map((tag) {
                    final isSelected = _selectedTag == tag;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTag = isSelected ? null : tag;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? clr.primary.withOpacity(0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? clr.primary
                                : (isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.label,
                              size: 14,
                              color: isSelected
                                  ? clr.primary
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? clr.primary
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[500]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  InkWell(
                    onTap: _showAddTagDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add,
                          size: 16,
                          color: isDark ? clr.secondary : Colors.grey[500]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              Text(
                'CONTENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 6,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.grey[200] : Colors.grey[700],
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing your note...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: const EdgeInsets.all(16),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  : const Icon(Icons.check, size: 22),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Note',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
