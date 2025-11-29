import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiReply {
  const GeminiReply({this.text, required this.images});

  final String? text;
  final List<GeminiImagePart> images;
}

class GeminiImagePart {
  const GeminiImagePart({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class GeminiService {
  GeminiService._(this._client);

  static final GeminiService instance = GeminiService._(http.Client());

  final http.Client _client;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<GeminiReply> sendMessage({
    required List<Map<String, dynamic>> contents,
    String? model,
  }) async {
    final apiKey =
        dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['GEMINI_AI_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY in .env');
    }

    final targetModel =
        model ?? dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    final uri = Uri.parse('$_baseUrl/$targetModel:generateContent?key=$apiKey');

    final body = jsonEncode({
      'contents': contents,
    });
    print(body);

    final response = await _client
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message =
          error is Map<String, dynamic> ? error['message'] : 'Unknown error';
      throw HttpException(
        'Gemini request failed (${response.statusCode}): $message',
      );
    }

    final candidates = payload['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw StateError('Gemini returned no candidates');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];

    final buffer = StringBuffer();
    final images = <GeminiImagePart>[];

    for (final part in parts) {
      if (part is! Map<String, dynamic>) {
        continue;
      }

      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(text.trim());
      }

      final inline =
          part['inline_data'] ?? part['inlineData'] as Map<String, dynamic>?;
      if (inline != null) {
        final data = inline['data'];
        if (data is String && data.isNotEmpty) {
          final bytes = base64Decode(data);
          final mime = inline['mime_type'] ?? inline['mimeType'] ?? 'image/png';
          images.add(GeminiImagePart(bytes: bytes, mimeType: mime));
        }
      }
    }

    final textResponse = buffer.toString().trim().isEmpty
        ? null
        : buffer.toString().trim();

    return GeminiReply(text: textResponse, images: images);
  }
}
