import 'dart:async';

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
      content: content.trim(),
    );
    _pushMessage(userMessage);

    isSendingNotifier.value = true;
    try {
      final client = OpenAIClient(
        apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
      );
      if (client.apiKey.isEmpty) {
        throw StateError('Missing OPENAI_API_KEY dart-define');
      }

      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-5'),
          messages: messagesNotifier.value.map<ChatCompletionMessage>((msg) {
            switch (msg.role) {
              case ChatRole.system:
                return ChatCompletionMessage.system(content: msg.content);
              case ChatRole.user:
                return ChatCompletionMessage.user(
                  content: ChatCompletionUserMessageContent.string(msg.content),
                );
              case ChatRole.assistant:
                return ChatCompletionMessage.assistant(content: msg.content);
            }
          }).toList(),
        ),
      );

      final assistantOutput = response.choices?.firstOrNull;
      final textValue = assistantOutput?.message.content;

      if (textValue == null || textValue.isEmpty) {
        throw StateError('OpenAI returned an empty response');
      }

      _pushMessage(ChatMessage(role: ChatRole.assistant, content: textValue));
    } catch (error, stackTrace) {
      debugPrint('Failed to send message: $error\n$stackTrace');
      _pushMessage(
        ChatMessage(
          role: ChatRole.system,
          content: 'Sorry, something went wrong. Please try again. ($error)',
          isError: true,
        ),
      );
    } finally {
      isSendingNotifier.value = false;
    }
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
    required this.content,
    this.isError = false,
  });

  final ChatRole role;
  final String content;
  final bool isError;
}

enum ChatRole { system, user, assistant }
