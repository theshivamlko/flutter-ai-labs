import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MistralService {
  MistralService._(this._client);
  static final MistralService instance = MistralService._(http.Client());

  final http.Client _client;

  // Mistral chat completions endpoint (chat-style API)
  static const String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';

  /// Sends chat-style messages to Mistral and returns the assistant text.
  ///
  /// - `messages` is a list of maps describing each message. Common shapes supported:
  ///   - { 'role': 'user'|'assistant'|'system', 'content': 'plain text' }
  ///   - { 'role': ..., 'content': [ { 'type': 'text', 'text': '...' } ] }
  /// The method will normalize content to the block-style that some Mistral endpoints expect.
  Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? model,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    final apiKey = dotenv.env['MISTRAL_API_KEY'];
    final selectedModel = model ?? dotenv.env['MISTRAL_MODEL'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('Missing MISTRAL_API_KEY. Create a .env file with your key.');
    }

    if (selectedModel == null || selectedModel.isEmpty) {
      throw StateError('Missing MISTRAL_MODEL. Set a default model in your .env or pass it explicitly.');
    }

    // Normalize messages to blocks that Mistral commonly accepts:
    // { role: 'user', content: [ { type: 'text', text: '...' } ] }
    final normalizedMessages = messages.map((m) {
      final role = m['role']?.toString() ?? 'user';
      final rawContent = m['content'];

      List<Map<String, dynamic>> contentBlocks = [];
      if (rawContent is String) {
        contentBlocks = [
          {'type': 'text', 'text': rawContent}
        ];
      } else if (rawContent is List) {
        // assume it's already a list of blocks
        contentBlocks = rawContent
            .whereType<Map>()
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
      } else if (rawContent is Map) {
        // single block map
        contentBlocks = [Map<String, dynamic>.from(rawContent)];
      } else {
        // fallback: try to stringify
        contentBlocks = [
          {'type': 'text', 'text': rawContent?.toString() ?? ''}
        ];
      }

      return {
        'role': role,
        'content': contentBlocks,
      };
    }).toList();

    final body = jsonEncode({
      'model': selectedModel,
      'messages': normalizedMessages,
      // Mistral endpoints use different names; include both to be compatible
      'max_new_tokens': maxTokens,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    };

    try {
      final resp = await _client
          .post(Uri.parse(_baseUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        // 1) Common OpenAI-like: choices[].message.content (string or blocks)
        if (data.containsKey('choices')) {
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final first = choices.first as Map<String, dynamic>;
            // message may be a map
            final message = first['message'] ?? first['delta'] ?? first;
            if (message is Map) {
              final content = message['content'];
              // content might be a string
              if (content is String && content.isNotEmpty) return content.trim();

              // or content might be a list of blocks
              if (content is List) {
                final buffer = StringBuffer();
                for (final block in content) {
                  if (block is Map) {
                    final t = block['text'] ?? block['content'] ?? block['payload'];
                    if (t is String && t.isNotEmpty) buffer.write(t);
                  } else if (block is String) {
                    buffer.write(block);
                  }
                }
                final result = buffer.toString().trim();
                if (result.isNotEmpty) return result;
              }

              // sometimes text is nested under 'content'[0]['text']
              if (message['content'] is List) {
                final list = message['content'] as List;
                if (list.isNotEmpty && list.first is Map) {
                  final text = (list.first as Map)['text'];
                  if (text is String && text.isNotEmpty) return text.trim();
                }
              }
            }

            // fallback: check for 'text' or 'output' on the choice
            final text = first['text'] ?? first['output'];
            if (text is String && text.isNotEmpty) return text.trim();
          }
        }

        // 2) Some APIs return outputs: [{ content: [ {type:'output_text', text: '...'} ] }]
        if (data.containsKey('outputs')) {
          final outputs = data['outputs'] as List<dynamic>?;
          if (outputs != null && outputs.isNotEmpty) {
            final out0 = outputs.first as Map<String, dynamic>;
            final content = out0['content'];
            if (content is List) {
              final buffer = StringBuffer();
              for (final block in content) {
                if (block is Map) {
                  final t = block['text'] ?? block['content'] ?? block['payload'] ?? block['data'];
                  if (t is String && t.isNotEmpty) buffer.write(t);
                } else if (block is String) {
                  buffer.write(block);
                }
              }
              final result = buffer.toString().trim();
              if (result.isNotEmpty) return result;
            }
          }
        }

        // 3) Some Mistral responses put the content under 'result' or 'text'
        final possibleText = data['text'] ?? data['result'] ?? data['completion'];
        if (possibleText is String && possibleText.isNotEmpty) return possibleText.trim();

        // 4) Last resort: search recursively for the first non-empty string value
        String? firstString;
        void search(dynamic node) {
          if (firstString != null) return;
          if (node is String && node.isNotEmpty) {
            firstString = node;
            return;
          }
          if (node is Map) {
            for (final v in node.values) {
              search(v);
              if (firstString != null) return;
            }
          }
          if (node is List) {
            for (final e in node) {
              search(e);
              if (firstString != null) return;
            }
          }
        }

        search(data);
        if (firstString != null) return firstString!.trim();

        throw const FormatException('Unexpected response format from Mistral');
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
        print('FormatException parsing Mistral response: $e\n$st');
      }
      rethrow;
    } on Exception catch (e) {
      throw Exception('Unexpected error calling Mistral: $e');
    }
  }
}
