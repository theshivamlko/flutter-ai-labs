import 'package:flutter/material.dart';
import 'package:flutter_openai_api_example_app/openai_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Chat Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final OpenAIChatService _chatService = OpenAIChatService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    await _chatService.sendMessage(content: text);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPT-5 Chat')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: _chatService.messagesNotifier,
                builder: (context, messages, _) {
                  if (messages.isEmpty) {
                    return const _EmptyChatState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message.role == ChatRole.user;
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: _ChatBubble(message: message, isUser: isUser),
                      );
                    },
                  );
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _chatService.isSendingNotifier,
              builder: (context, isSending, _) {
                if (!isSending) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _TypingIndicator(),
                );
              },
            ),
            _MessageComposer(
              controller: _textController,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask anything...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isUser});

  final ChatMessage message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = message.isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant;
    final fgColor = message.isError
        ? theme.colorScheme.onErrorContainer
        : isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant;

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message.content, style: theme.textTheme.bodyMedium?.copyWith(color: fgColor)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text('GPT-5 is thinking...'),
      ],
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Start a conversation with GPT-5 by typing below.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
