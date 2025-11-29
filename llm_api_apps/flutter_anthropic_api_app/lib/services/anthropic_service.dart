import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AnthropicService {
  AnthropicService._(this._client);
  static final AnthropicService instance = AnthropicService._(http.Client());

  final http.Client _client;

  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? model,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    final selectedModel = model ?? dotenv.env['ANTHROPIC_MODEL'] ;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('Missing ANTHROPIC_API_KEY. Create a .env file with your key.');
    }

    final body = jsonEncode({
      'model': selectedModel,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': messages,
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };


    try {
      final resp = await _client
          .post(Uri.parse(_baseUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // response.messages[].content is a list of blocks; grab text blocks
        final content = data['content'] as List<dynamic>?;
        if (content != null && content.isNotEmpty) {
          final buffer = StringBuffer();
          for (final block in content) {
            if (block is Map && block['type'] == 'text' && block['text'] is String) {
              buffer.write(block['text'] as String);
            }
          }
          final result = buffer.toString().trim();
          if (result.isNotEmpty) return result;
        }
        // Fallbacks if schema varies
        final text = data['text'] ?? data['completion'];
        if (text is String && text.isNotEmpty) return text;
        throw const FormatException('Unexpected response format from Anthropic');
      }

      if (resp.statusCode == 401) {
        throw const HttpException('Unauthorized (401): invalid API key');
      }
      if (resp.statusCode == 429) {
        throw const HttpException('Rate limited (429): please retry later');
      }
      if (resp.statusCode >= 500) {
        throw HttpException('Server error (${resp.statusCode})');
      }

      throw HttpException('Request failed (${resp.statusCode}): ${resp.body}');
    } on SocketException {
      rethrow;
    } on HttpException {
      rethrow;
    } on FormatException catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('FormatException parsing Anthropic response: $e\n$st');
      }
      rethrow;
    } on Exception catch (e) {
      throw Exception('Unexpected error calling Anthropic: $e');
    }
  }
}

