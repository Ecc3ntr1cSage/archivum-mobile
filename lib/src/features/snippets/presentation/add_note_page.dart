import 'package:flutter/material.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
          icon: Icon(Icons.arrow_back, color: isDark ? clr.secondary : Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Note',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.push_pin_outlined, color: isDark ? clr.secondary : Colors.grey[600]),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TITLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter title here...',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: clr.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label, size: 16, color: clr.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Ideas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: clr.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16, color: isDark ? clr.secondary : Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Add Tag',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 16, color: isDark ? clr.secondary : Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Edited 2m ago',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start typing your note...',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.image_outlined, color: isDark ? clr.secondary : Colors.grey[500]),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.format_list_bulleted, color: isDark ? clr.secondary : Colors.grey[500]),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.palette_outlined, color: isDark ? clr.secondary : Colors.grey[500]),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clr.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: clr.primary.withOpacity(0.4),
                    ),
                    onPressed: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Note',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
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
