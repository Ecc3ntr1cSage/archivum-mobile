import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<Map<String, String>> _notes = [];
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();

  void _save() {
    final t = _title.text.trim();
    final c = _content.text.trim();
    if (t.isEmpty && c.isEmpty) return;
    setState(() {
      _notes.insert(0, {'title': t, 'content': c});
      _title.clear();
      _content.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextFormField(controller: _title, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 8),
          TextFormField(controller: _content, maxLines: 4, decoration: const InputDecoration(hintText: 'Content')),
          const SizedBox(height: 8),
          Row(children: [ElevatedButton(onPressed: _save, child: const Text('Save'))]),
          const SizedBox(height: 12),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes yet'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, idx) {
                      final n = _notes[idx];
                      return ListTile(
                        title: Text(n['title'] ?? ''),
                        subtitle: Text(n['content'] ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
