import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

/// Global chat service that keeps the entire conversation in memory.
class OpenAIChatService {
  OpenAIChatService._();

  static final OpenAIChatService instance = OpenAIChatService._();

  /// Backing store for all messages rendered in the UI.
  final ValueNotifier<List<ChatMessage>> messagesNotifier =
      ValueNotifier<List<ChatMessage>>(<ChatMessage>[]);

  /// Emits the current sending status so the UI can show a typing indicator.
  final ValueNotifier<bool> isSendingNotifier = ValueNotifier<bool>(false);

  /// Append a new user prompt and fetch assistant response.
  Future<void> sendMessage({required String content}) async {
    if (content.trim().isEmpty || isSendingNotifier.value) {
      return;
    }

    final userMessage = ChatMessage(
      role: ChatRole.user,
      text: content.trim(),
    );
    _pushMessage(userMessage);

    isSendingNotifier.value = true;
    try {
      final response = await _createClient().createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o'),
          messages: _buildTextOnlyHistory(),
          modalities: [
            ChatCompletionModality.text,
          ],
        ),
      );

      final assistantOutput = response.choices.firstOrNull;
      final textValue = assistantOutput?.message.content;

      if (textValue == null || textValue.isEmpty) {
        throw StateError('OpenAI returned an empty response');
      }

      _pushMessage(ChatMessage(role: ChatRole.assistant, text: textValue));
    } catch (error, stackTrace) {
      debugPrint('Failed to send message: $error\n$stackTrace');
      _pushMessage(
        ChatMessage(
          role: ChatRole.system,
          text: 'Sorry, something went wrong. Please try again. ($error)',
          isError: true,
        ),
      );
    } finally {
      isSendingNotifier.value = false;
    }
  }

  Future<void> generateImage({required String prompt}) async {
    if (prompt.trim().isEmpty || isSendingNotifier.value) {
      return;
    }

    final sanitizedPrompt = prompt.trim();
    _pushMessage(
      ChatMessage(role: ChatRole.user, text: sanitizedPrompt),
    );

    isSendingNotifier.value = true;
    try {
      final response = await _createClient().createImage(

        request: CreateImageRequest(

          model: CreateImageRequestModel.model(ImageModels.gptImage1),

          prompt: sanitizedPrompt,
          size: ImageSize.auto,
        ),
      );

      final imageData = response.data?.firstOrNull;
      final base64Image = imageData?.b64Json;
      if (base64Image == null || base64Image.isEmpty) {
        throw StateError('OpenAI returned an empty image payload');
      }

      _pushMessage(
        ChatMessage(
          role: ChatRole.assistant,
          text: imageData?.revisedPrompt ?? 'Here is your image.',
          imageBytes: base64Decode(base64Image),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to generate image: $error\n$stackTrace');
      _pushMessage(
        ChatMessage(
          role: ChatRole.system,
          text: 'Image generation failed. Please try again. ($error)',
          isError: true,
        ),
      );
    } finally {
      isSendingNotifier.value = false;
    }
  }

  OpenAIClient _createClient() {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw StateError('Missing OPENAI_API_KEY in .env');
    }
    return OpenAIClient(apiKey: apiKey,organization:dotenv.env['ORGANIZATION'] );
  }

  List<ChatCompletionMessage> _buildTextOnlyHistory() {
    return messagesNotifier.value
        .where((msg) => !msg.hasImage)
        .map((msg) {
          switch (msg.role) {
            case ChatRole.system:
              return ChatCompletionMessage.system(content: msg.text ?? '');
            case ChatRole.user:
              return ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.string(msg.text ?? ''),
              );
            case ChatRole.assistant:
              return ChatCompletionMessage.assistant(content: msg.text ?? '');
          }
        })
        .toList();
  }

  void _pushMessage(ChatMessage message) {
    messagesNotifier.value = List<ChatMessage>.unmodifiable(<ChatMessage>[
      ...messagesNotifier.value,
      message,
    ]);
  }
}

/// Simple in-memory chat message representation.
class ChatMessage {
  ChatMessage({
    required this.role,
    this.text,
    this.imageBytes,
    this.isError = false,
  }) : assert(text != null || imageBytes != null, 'ChatMessage requires text or image');

  final ChatRole role;
  final String? text;
  final Uint8List? imageBytes;
  final bool isError;

  bool get hasImage => imageBytes != null;
}

enum ChatRole { system, user, assistant }
