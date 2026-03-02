import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/openrouter_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });
}

final chatControllerProvider =
    NotifierProvider<ChatController, List<ChatMessage>>(() {
  return ChatController();
});

class ChatController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: 'Hi! I\'m your **Archivum Agent** 🗂️\n\n'
            'I can generate SQL for your queries and then reason over the results. '
            'What would you like to search today?',
        isUser: false,
      ),
    ];
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    final openRouterService = ref.read(openRouterServiceProvider);

    // Add user message to UI
    state = [
      ...state,
      ChatMessage(text: prompt, isUser: true),
      ChatMessage(text: '...', isUser: false, isLoading: true), // Placeholder
    ];

    // Call service
    final response = await openRouterService.getAiResponse(prompt);

    // Replace placeholder with final answer
    final newState = List<ChatMessage>.from(state);
    newState[newState.length - 1] =
        ChatMessage(text: response, isUser: false);
    state = newState;
  }
}
