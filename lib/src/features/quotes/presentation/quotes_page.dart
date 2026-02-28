import 'package:flutter/material.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _quotes = [];

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _quotes.insert(0, text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextFormField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write a quote...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _quotes.isEmpty
                ? const Center(child: Text('No quotes yet'))
                : ListView.separated(
                    itemCount: _quotes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) => ListTile(
                      title: Text(_quotes[idx]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
