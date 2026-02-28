import 'package:flutter/material.dart';

class AddQuotePage extends StatefulWidget {
  const AddQuotePage({super.key});

  @override
  State<AddQuotePage> createState() => _AddQuotePageState();
}

class _AddQuotePageState extends State<AddQuotePage> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  
  String _selectedCategory = 'Motivation';
  final List<String> _categories = ['Motivation', 'Wisdom', 'Life'];

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clr = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: clr.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quotes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: clr.secondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture Inspiration',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write down words that move you, remind you, or inspire you.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Quote Area
                  Text(
                    'Your Quote',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[50],
                      border: Border.all(
                        color: clr.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: TextField(
                            controller: _quoteController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                              color: isDark ? Colors.grey[200] : Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              hintText: '“The only limit to our realization of tomorrow will be our doubts of today.”',
                              hintStyle: TextStyle(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(
                            Icons.format_quote,
                            size: 48,
                            color: (isDark ? Colors.grey[600] : Colors.grey[400])?.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Author Field
                  Text(
                    'Author (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Who said this?',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: clr.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Category Field
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? clr.secondary : (isDark ? Colors.grey[800] : Colors.white),
                              border: Border.all(
                                color: isSelected ? clr.secondary : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                  ? Colors.white 
                                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ),
                          ),
                        );
                      }),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clr.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: clr.primary.withOpacity(0.4),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Save Quote',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor.withOpacity(0.5) : Colors.grey[50]?.withOpacity(0.5),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BottomNavItem(
                    icon: Icons.add_circle,
                    label: 'NEW',
                    isActive: true,
                    activeColor: clr.primary,
                    inactiveColor: isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  ),
                  const SizedBox(width: 32),
                  _BottomNavItem(
                    icon: Icons.format_list_bulleted,
                    label: 'COLLECTION',
                    isActive: false,
                    activeColor: clr.primary,
                    inactiveColor: isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  ),
                  const SizedBox(width: 32),
                  _BottomNavItem(
                    icon: Icons.settings,
                    label: 'SETTINGS',
                    isActive: false,
                    activeColor: clr.primary,
                    inactiveColor: isDark ? Colors.grey[500]! : Colors.grey[400]!,
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
