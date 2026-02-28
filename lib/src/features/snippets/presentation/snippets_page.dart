import 'package:flutter/material.dart';

import 'add_note_page.dart';
import 'add_quote_page.dart';

class SnippetsPage extends StatefulWidget {
  const SnippetsPage({super.key});

  @override
  State<SnippetsPage> createState() => _SnippetsPageState();
}

class _SnippetsPageState extends State<SnippetsPage> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Snippets', 'Notes', 'Quotes'];

  Widget _header(BuildContext context, bool isDark, ColorScheme clr) {
    return Container(
      color: isDark ? const Color(0xFF191121).withOpacity(0.8) : const Color(0xFFF7F6F8).withOpacity(0.8),
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
                  child: Icon(Icons.auto_awesome_motion, color: clr.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Snippets', style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                )),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {}, 
                  icon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  splashRadius: 24,
                ),
                IconButton(
                  onPressed: () {}, 
                  icon: Icon(Icons.filter_list, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  splashRadius: 24,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _quickAdd(BuildContext context, ColorScheme clr) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: clr.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNotePage()),
              );
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: clr.secondary, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddQuotePage()),
              );
            },
            icon: const Icon(Icons.format_quote),
            label: const Text('New Quote', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _filterTabs(BuildContext context, bool isDark, ColorScheme clr) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF3D2D4D) : Colors.grey[300]!)),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 12, right: 8, left: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? clr.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected 
                    ? clr.primary 
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _noteCard(BuildContext context, bool isDark, ColorScheme clr, {required String title, required String excerpt, required String time, bool isAccent = false, String? tag}) {
    final bgColor = isDark ? const Color(0xFF2A1F36) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D2D4D) : Colors.grey[200]!;
    final headerColor = isAccent ? clr.secondary : clr.primary;

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
                  headerColor.withOpacity(isAccent ? 0.2 : 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: clr.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NOTE', 
                style: TextStyle(
                  color: clr.primary, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      time, 
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  excerpt, 
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600], 
                    fontSize: 14,
                  ), 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3D2D4D) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
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
                              width: 24, height: 24, 
                              decoration: BoxDecoration(
                                color: clr.secondary, 
                                shape: BoxShape.circle, 
                                border: Border.all(color: isDark ? const Color(0xFF2A1F36) : Colors.white, width: 2),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              child: Container(
                                width: 24, height: 24, 
                                decoration: BoxDecoration(
                                  color: clr.primary, 
                                  shape: BoxShape.circle, 
                                  border: Border.all(color: isDark ? const Color(0xFF2A1F36) : Colors.white, width: 2),
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
                          Text('Open Note', style: TextStyle(color: clr.primary, fontWeight: FontWeight.w600, fontSize: 14)), 
                          const SizedBox(width: 4), 
                          Icon(Icons.arrow_forward, size: 16, color: clr.primary),
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

  Widget _quoteCard(BuildContext context, bool isDark, ColorScheme clr, {required String quote, String? author, required String time, bool isAccent = false}) {
    final bgColor = isDark ? const Color(0xFF2A1F36) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D2D4D) : Colors.grey[200]!;

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
              color: (isAccent ? clr.primary : clr.secondary).withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                      decoration: BoxDecoration(
                        color: clr.secondary.withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(4),
                      ), 
                      child: Text(
                        'QUOTE', 
                        style: TextStyle(
                          color: clr.secondary, 
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      time, 
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '"$quote"', 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[100] : Colors.black87,
                    height: 1.5,
                  ),
                ),
                if (author != null) 
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0), 
                    child: Text(
                      '— $author', 
                      style: TextStyle(
                        color: clr.secondary, 
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
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
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
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        iconSize: 18,
                        onPressed: () {}, 
                        icon: Icon(Icons.favorite, color: Colors.grey[400]),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _header(context, isDark, clr),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _quickAdd(context, clr),
                    const SizedBox(height: 24),
                    _filterTabs(context, isDark, clr),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _noteCard(
                                  context, isDark, clr,
                                  title: 'Project Ideas 2024', 
                                  excerpt: 'A collection of innovative thoughts for the upcoming year including mobile app frameworks and decentralized databases...', 
                                  time: '2h ago',
                                ),
                                const SizedBox(height: 16),
                                if (!isWide) ...[
                                  _quoteCard(
                                    context, isDark, clr,
                                    quote: 'The only way to do great work is to love what you do.', 
                                    author: 'Steve Jobs', 
                                    time: 'Yesterday',
                                  ),
                                  const SizedBox(height: 16),
                                  _noteCard(
                                    context, isDark, clr,
                                    title: 'Grocery List', 
                                    excerpt: 'Almond milk, organic coffee beans, sourdough bread, avocados, and fresh basil for dinner tonight.', 
                                    time: '5h ago',
                                    isAccent: true,
                                    tag: '#shopping',
                                  ),
                                  const SizedBox(height: 16),
                                  _quoteCard(
                                    context, isDark, clr,
                                    quote: 'Your time is limited, so don\'t waste it living someone else\'s life.', 
                                    author: 'Steve Jobs', 
                                    time: 'Mar 12',
                                    isAccent: true,
                                  ),
                                ],
                                if (isWide)
                                  _noteCard(
                                    context, isDark, clr,
                                    title: 'Grocery List', 
                                    excerpt: 'Almond milk, organic coffee beans, sourdough bread, avocados, and fresh basil for dinner tonight.', 
                                    time: '5h ago',
                                    isAccent: true,
                                    tag: '#shopping',
                                  ),
                              ],
                            ),
                          ),
                          if (isWide) const SizedBox(width: 16),
                          if (isWide)
                            Expanded(
                              child: Column(
                                children: [
                                  _quoteCard(
                                    context, isDark, clr,
                                    quote: 'The only way to do great work is to love what you do.', 
                                    author: 'Steve Jobs', 
                                    time: 'Yesterday',
                                  ),
                                  const SizedBox(height: 16),
                                  _quoteCard(
                                    context, isDark, clr,
                                    quote: 'Your time is limited, so don\'t waste it living someone else\'s life.', 
                                    author: 'Steve Jobs', 
                                    time: 'Mar 12',
                                    isAccent: true,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    })
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
