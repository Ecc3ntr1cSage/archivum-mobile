import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/env.dart';

final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

class OpenRouterService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'minimax/minimax-m2.5';

  // SupabaseClient is accessed lazily to avoid provider timing issues.
  SupabaseClient get _supabase => Supabase.instance.client;

  //  Public entry point 

  Future<String> getAiResponse(String userPrompt) async {
    try {
      final apiKey = Env.openrouterApiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenRouter API key is missing. Check your .env file.');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated.');
      }

      //  Step 1: Intent + optional SQL generation (single model call) 
      final intentRaw = await _callModel(
        apiKey: apiKey,
        systemPrompt: _buildSystemPrompt(userId),
        userMessage: userPrompt,
      );

      final intent = intentRaw.trim();

      //  Step 2: Route on prefix 
      if (intent.startsWith('DIRECT:')) {
        return _cleanResponse(intent);
      }

      // Extract the SQL query (anything else is treated as SQL: prefix).
      final sql = _cleanResponse(intent);
      if (sql.isEmpty) {
        return 'I could not generate a valid query for that request.';
      }

      //  Step 3: Execute query via Supabase RPC 
      final rpcResult = await _supabase
          .rpc('run_agent_query', params: {'sql_query': sql});

      final dbData = jsonEncode(rpcResult ?? []);

      //  Step 4: Synthesise a plain-language answer 
      final answer = await _callModel(
        apiKey: apiKey,
        systemPrompt: null,
        userMessage: 'The user asked: "$userPrompt"\n\n'
            'We ran this SQL query:\n$sql\n\n'
            'The database returned:\n$dbData\n\n'
            'Explain the findings to the user in plain, friendly language. '
            'Be concise. Do not repeat the SQL or raw JSON.',
      );

      return _cleanResponse(answer);
    } catch (e) {
      return 'Error: $e';
    }
  }

  //  System prompt with mini-DDL 

  String _buildSystemPrompt(String userId) {
    return '''
You are Archivum Agent, a SQL assistant for a personal archiving app.

DATABASE SCHEMA (Supabase / PostgreSQL):
  notes        (id uuid, user_id uuid, title text, content text, tag text, color text, created_at timestamptz)
  quotes       (id uuid, user_id uuid, content text, author text, tag text, color text, created_at timestamptz)
  accounts     (id uuid, user_id uuid, title text, method text, email text, username text, password text, provider text, tags text, created_at timestamptz)
  transactions (id uuid, user_id uuid, status int [0=income 1=expense], amount int [cents], details text, tag text, created_at timestamptz)
  prayers      (id int, user_id uuid, date date, fajr bool, dhuhr bool, asr bool, maghrib bool, isha bool)
  indexes      (id int, user_id uuid, title text, created_at timestamptz)
  index_items  (id int, index_id int, item text, status int, created_at timestamptz)
  tags         (id uuid, user_id uuid, text text, feature text, created_at timestamptz)

RULES:
1. ALWAYS filter every query with: user_id = '$userId'
   For index_items, join through indexes:
   index_items JOIN indexes ON index_items.index_id = indexes.id WHERE indexes.user_id = '$userId'
2. Only write SELECT queries. Never DELETE, INSERT, UPDATE, DROP, or ALTER.
3. If the request needs database data, respond EXACTLY as (no markdown, no backticks, no explanation):
   SQL:<raw SELECT query>
4. If the request is a general question that does not need database data, respond EXACTLY as:
   DIRECT:<your answer>
5. Do not include any text before or after the prefix.
''';
  }

  //  Helpers 

  /// Strips SQL:/DIRECT: prefixes, markdown code fences, trailing semicolons,
  /// and excess whitespace.
  String _cleanResponse(String raw) {
    return raw
        .replaceAll(RegExp(r'^(SQL:|DIRECT:)'), '')
        .replaceAll(RegExp(r'```sql|```'), '')
        .trim()
        .replaceAll(RegExp(r';+$'), '');
  }

  Future<String> _callModel({
    required String apiKey,
    required String? systemPrompt,
    required String userMessage,
  }) async {
    final messages = <Map<String, String>>[
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com',
        'X-Title': 'Archivum Agent',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'Failed to reach OpenRouter ($_model): ${response.body}');
    }
  }
}
