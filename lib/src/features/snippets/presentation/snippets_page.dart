import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_note_page.dart';
import 'add_quote_page.dart';
import '../../indexes/presentation/add_index_page.dart';
import '../../indexes/presentation/index_detail_page.dart';
import '../../../core/providers/snippet_repository_provider.dart';
import '../../notes/domain/note.dart';
import '../../quotes/domain/quote.dart';
import '../../indexes/domain/index_item.dart';

class SnippetsPage extends ConsumerStatefulWidget {
  const SnippetsPage({super.key});

  @override
  ConsumerState<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends ConsumerState<SnippetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesSearchController = TextEditingController();
  final TextEditingController _quotesSearchController = TextEditingController();
  final TextEditingController _indexesSearchController = TextEditingController();
  String _notesSearchQuery = '';
  String _quotesSearchQuery = '';
  String _indexesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesSearchController.addListener(() {
      setState(() => _notesSearchQuery = _notesSearchController.text.toLowerCase());
    });
    _quotesSearchController.addListener(() {
      setState(() => _quotesSearchQuery = _quotesSearchController.text.toLowerCase());
    });
    _indexesSearchController.addListener(() {
      setState(() => _indexesSearchQuery = _indexesSearchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesSearchController.dispose();
    _quotesSearchController.dispose();
    _indexesSearchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _header(BuildContext context, bool isDark, ColorScheme clr) {
    return Container(
      color: isDark
          ? const Color(0xFF191121).withOpacity(0.8)
          : const Color(0xFFF7F6F8).withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: clr.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome_motion,
                      color: clr.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Snippets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.filter_list,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, ColorScheme clr, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1626) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: clr.primary.withOpacity(0.1),
                    child: Icon(Icons.edit_note, color: clr.primary),
                  ),
                  title: const Text('Add Note',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddNotePage()),
                    ).then((_) => ref.invalidate(notesListProvider));
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: clr.secondary.withOpacity(0.1),
                    child:
                        Icon(Icons.format_quote, color: clr.secondary),
                  ),
                  title: const Text('Add Quote',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddQuotePage()),
                    ).then((_) => ref.invalidate(quotesListProvider));
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child:
                        const Icon(Icons.list_alt, color: Colors.green),
                  ),
                  title: const Text('Add Index',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddIndexPage()),
                    ).then((_) => ref.invalidate(indexesListProvider));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _searchBar(
      TextEditingController controller, bool isDark, ColorScheme clr,
      {String hint = 'Search...'}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1F36) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF3D2D4D) : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
          prefixIcon:
              Icon(Icons.search, color: clr.primary.withOpacity(0.6), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 18,
                      color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  onPressed: () => controller.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _noteCard(
      BuildContext context, bool isDark, ColorScheme clr, Note note) {
    final bgColor = isDark ? const Color(0xFF2A1F36) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D2D4D) : Colors.grey[200]!;

    Color headerColor = clr.primary;
    if (note.color != null) {
      if (note.color == 'accent' || note.color == 'secondary') {
        headerColor = clr.secondary;
      } else if (note.color!.startsWith('#')) {
        try {
          headerColor =
              Color(int.parse(note.color!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 128,
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  headerColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(note.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.tag != null && note.tag!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3D2D4D)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.tag!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 40,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: clr.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2A1F36)
                                        : Colors.white,
                                    width: 2),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: clr.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF2A1F36)
                                          : Colors.white,
                                      width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text('Open Note',
                              style: TextStyle(
                                  color: clr.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 16, color: clr.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _quoteCard(
      BuildContext context, bool isDark, ColorScheme clr, Quote quote) {
    final bgColor = isDark ? const Color(0xFF2A1F36) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D2D4D) : Colors.grey[200]!;

    Color quoteColor = clr.secondary;
    if (quote.color != null) {
      if (quote.color == 'primary') {
        quoteColor = clr.primary;
      } else if (quote.color!.startsWith('#')) {
        try {
          quoteColor =
              Color(int.parse(quote.color!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -16,
            left: -16,
            child: Icon(
              Icons.format_quote,
              size: 120,
              color: quoteColor.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quoteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Quote',
                        style: TextStyle(
                          color: quoteColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(quote.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '"${quote.content}"',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[100] : Colors.black87,
                    height: 1.5,
                  ),
                ),
                if (quote.author != null && quote.author!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      '— ${quote.author}',
                      style: TextStyle(
                        color: quoteColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        iconSize: 18,
                        onPressed: () {},
                        icon: Icon(Icons.share, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        iconSize: 18,
                        onPressed: () {},
                        icon:
                            Icon(Icons.favorite, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indexCard(
      BuildContext context, bool isDark, ColorScheme clr, IndexEntry index) {
    final bgColor = isDark ? const Color(0xFF2A1F36) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D2D4D) : Colors.grey[200]!;
    const indexColor = Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  indexColor.withOpacity(0.2),
                  indexColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: indexColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Index',
                    style: TextStyle(
                      color: indexColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  _formatDateTime(index.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: indexColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        index.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Show up to 3 items preview
                ...index.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: indexColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.item,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (index.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${index.items.length - 3} more items',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${index.items.length} items',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndexDetailPage(index: index),
                          ),
                        ).then((_) => ref.invalidate(indexesListProvider));
                      },
                      child: const Row(
                        children: [
                          Text('Open List',
                              style: TextStyle(
                                  color: indexColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 16, color: indexColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(bool isDark, ColorScheme clr) {
    final notesAsync = ref.watch(notesListProvider);
    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (notes) {
        final filtered = _notesSearchQuery.isEmpty
            ? notes
            : notes.where((n) {
                return n.title.toLowerCase().contains(_notesSearchQuery) ||
                    n.content.toLowerCase().contains(_notesSearchQuery) ||
                    (n.tag?.toLowerCase().contains(_notesSearchQuery) ?? false);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(notesListProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _searchBar(_notesSearchController, isDark, clr,
                  hint: 'Search notes...'),
              if (filtered.isEmpty)
                _emptyState(clr, isDark, Icons.edit_note, 'No notes found')
              else
                ...filtered.map((note) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _noteCard(context, isDark, clr, note),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotesTab(bool isDark, ColorScheme clr) {
    final quotesAsync = ref.watch(quotesListProvider);
    return quotesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (quotes) {
        final filtered = _quotesSearchQuery.isEmpty
            ? quotes
            : quotes.where((q) {
                return q.content.toLowerCase().contains(_quotesSearchQuery) ||
                    (q.author?.toLowerCase().contains(_quotesSearchQuery) ??
                        false) ||
                    (q.tag?.toLowerCase().contains(_quotesSearchQuery) ??
                        false);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(quotesListProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _searchBar(_quotesSearchController, isDark, clr,
                  hint: 'Search quotes...'),
              if (filtered.isEmpty)
                _emptyState(
                    clr, isDark, Icons.format_quote, 'No quotes found')
              else
                ...filtered.map((quote) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _quoteCard(context, isDark, clr, quote),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexesTab(bool isDark, ColorScheme clr) {
    final indexesAsync = ref.watch(indexesListProvider);
    return indexesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (indexes) {
        final filtered = _indexesSearchQuery.isEmpty
            ? indexes
            : indexes.where((idx) {
                return idx.title
                        .toLowerCase()
                        .contains(_indexesSearchQuery) ||
                    idx.items.any((item) => item.item
                        .toLowerCase()
                        .contains(_indexesSearchQuery));
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(indexesListProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _searchBar(_indexesSearchController, isDark, clr,
                  hint: 'Search indexes...'),
              if (filtered.isEmpty)
                _emptyState(
                    clr, isDark, Icons.list_alt, 'No indexes found')
              else
                ...filtered.map((index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _indexCard(context, isDark, clr, index),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(
      ColorScheme clr, bool isDark, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: clr.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;
    final bgColor =
        isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context, clr, isDark),
        backgroundColor: clr.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [
          _header(context, isDark, clr),
          TabBar(
            controller: _tabController,
            labelColor: clr.primary,
            unselectedLabelColor:
                isDark ? Colors.grey[500] : Colors.grey[600],
            indicatorColor: clr.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Notes'),
              Tab(text: 'Quotes'),
              Tab(text: 'Indexes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(isDark, clr),
                _buildQuotesTab(isDark, clr),
                _buildIndexesTab(isDark, clr),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
