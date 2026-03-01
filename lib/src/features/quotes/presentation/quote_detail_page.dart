import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../quotes/domain/quote.dart';
import '../../../core/providers/quote_repository_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';

class QuoteDetailPage extends ConsumerStatefulWidget {
  final Quote quote;

  const QuoteDetailPage({super.key, required this.quote});

  @override
  ConsumerState<QuoteDetailPage> createState() => _QuoteDetailPageState();
}

class _QuoteDetailPageState extends ConsumerState<QuoteDetailPage> {
  late Quote _currentQuote;
  bool _isEditMode = false;
  bool _isSaving = false;

  // Edit mode controllers
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  String? _selectedTag;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _currentQuote = widget.quote;
    Future.microtask(() => _loadTags());
  }

  @override
  void dispose() {
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final tags = await ref.read(quoteRepositoryProvider).getTags('quote');
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
      _contentController.text = _currentQuote.content;
      _authorController.text = _currentQuote.author ?? '';
      _selectedTag = _currentQuote.tag;
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
    });
  }

  Future<void> _saveEdit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote content is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final author = _authorController.text.trim();
      final updatedQuote = _currentQuote.copyWith(
        content: content,
        author: author.isEmpty ? null : author,
        tag: _selectedTag,
      );

      final repo = ref.read(quoteRepositoryProvider);
      final result = await repo.updateQuote(updatedQuote);

      if (!mounted) return;
      setState(() {
        _currentQuote = result;
        _isEditMode = false;
      });
      ref.invalidate(quotesListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteQuote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text(
            'Are you sure you want to delete this quote? This action cannot be undone.'),
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
      final repo = ref.read(quoteRepositoryProvider);
      await repo.deleteQuote(_currentQuote.id!);
      ref.invalidate(quotesListProvider);
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
                  await ref.read(quoteRepositoryProvider).addTag(text, 'quote');
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

    // Determine quote color
    Color quoteColor = clr.secondary;
    if (_currentQuote.color != null) {
      if (_currentQuote.color == 'primary') {
        quoteColor = clr.primary;
      } else if (_currentQuote.color!.startsWith('#')) {
        try {
          quoteColor = Color(
              int.parse(_currentQuote.color!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
    }

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
          _isEditMode ? 'Edit Quote' : 'Quote',
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
                    if (value == 'delete') _deleteQuote();
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
          : _buildViewBody(isDark, clr, surfaceColor, borderColor, quoteColor),
    );
  }

  // ─── VIEW MODE ────────────────────────────────────────────────────────

  Widget _buildViewBody(bool isDark, ColorScheme clr, Color surfaceColor,
      Color borderColor, Color quoteColor) {
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
                  quoteColor.withOpacity(isDark ? 0.15 : 0.1),
                  quoteColor.withOpacity(isDark ? 0.05 : 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: quoteColor.withOpacity(isDark ? 0.2 : 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: quoteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.format_quote, color: quoteColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentQuote.tag != null &&
                          _currentQuote.tag!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: quoteColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _currentQuote.tag!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: quoteColor,
                            ),
                          ),
                        ),
                      if (_currentQuote.createdAt != null)
                        Text(
                          'Added ${_formatDate(_currentQuote.createdAt!)}',
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

          // Quote body
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              children: [
                // Decorative quote mark
                Positioned(
                  top: -8,
                  left: -8,
                  child: Icon(
                    Icons.format_quote,
                    size: 80,
                    color: quoteColor.withOpacity(0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${_currentQuote.content}"',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: isDark ? Colors.grey[100] : Colors.black87,
                      ),
                    ),
                    if (_currentQuote.author != null &&
                        _currentQuote.author!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 2,
                            decoration: BoxDecoration(
                              color: quoteColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _currentQuote.author!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: quoteColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
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
              // Quote content
              Text(
                'QUOTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: '"Enter your quote here..."',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Author
              Text(
                'AUTHOR (Optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _authorController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Who said this?',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400]),
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
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? clr.secondary
                              : (isDark ? Colors.grey[800] : Colors.white),
                          border: Border.all(
                            color: isSelected
                                ? clr.secondary
                                : (isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700]),
                          ),
                        ),
                      ),
                    );
                  }),
                  InkWell(
                    onTap: _showAddTagDialog,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey[700] : Colors.grey[200],
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color:
                            isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
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
                backgroundColor: clr.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: clr.secondary.withOpacity(0.4),
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
                _isSaving ? 'Saving...' : 'Save Quote',
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
