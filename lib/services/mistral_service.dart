import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MistralService {
  MistralService._(this._client);

  static final MistralService instance = MistralService._(http.Client());

  final http.Client _client;

  static const String _baseUrl = 'https://api.mistral.ai/v1/conversations';

  Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? model,
  }) async {
    // minimal setup: read API key and model (no verbose validation)
    final apiKey = dotenv.env['MISTRAL_API_KEY'];
    final selectedModel =
        model ?? dotenv.env['MISTRAL_MODEL'] ?? 'mistral-medium-latest';

    final body = jsonEncode({
      'model': selectedModel,
      'inputs': messages,

      'instructions': '',
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey ?? '',
      'Accept': 'application/json',
    };

    final resp = await _client
        .post(Uri.parse(_baseUrl), headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Request failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body);

    return data['outputs'][0]['content'];
  }
}
