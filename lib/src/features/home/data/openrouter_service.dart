import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/env.dart';

final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

class OpenRouterService {
  final String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> getAiResponse(String userPrompt) async {
    try {
      final apiKey = Env.openrouterApiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenRouter API Key is missing. Check your .env file.');
      }

      // Step 1: Generate SQL with MiniMax M2.5
      String sqlQuery = await _callModel(
        apiKey: apiKey,
        model: "minimax/minimax-m2.5",
        prompt: "Convert this request to a valid PostgreSQL/Supabase query: $userPrompt. Return ONLY the raw SQL string without formatting or explanation.",
      );

      // Step 2: [LOCAL STEP] We would execute the command here.
      // For demonstration, simulating database row count response...
      String dbData = "Result: 50 orders/notes found for this parameter.";

      // Step 3: Reason over the results with MiniMax M2.5
      String finalReasoning = await _callModel(
        apiKey: apiKey,
        model: "minimax/minimax-m2.5",
        prompt: "User asked: $userPrompt. \n\nWe executed this SQL: $sqlQuery \n\nThe database returned: $dbData. \n\nExplain this to the user simply.",
      );

      return finalReasoning;
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> _callModel({
    required String apiKey,
    required String model,
    required String prompt,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com', // Needed by OpenRouter
        'X-Title': 'Archivum Agent',
      },
      body: jsonEncode({
        'model': model,        'max_tokens': 2048,        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to reach OpenRouter ($model): ${response.body}');
    }
  }
}
