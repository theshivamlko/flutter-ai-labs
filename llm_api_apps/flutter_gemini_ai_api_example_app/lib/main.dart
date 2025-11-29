import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/gemini_ai_service.dart';

const Color _accentGreen = Color(0xFF22C55E);
const Color _scaffoldColor = Color(0xFF05080F);
const Color _surfaceColor = Color(0xFF111827);
const Color _appBarColor = Color(0xFF020617);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkBase = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemini Chat in Flutter',
      theme: darkBase.copyWith(
        colorScheme: darkBase.colorScheme.copyWith(
          primary: _accentGreen,
          secondary: _accentGreen,
          surface: _surfaceColor,
          background: _scaffoldColor,
          tertiary: const Color(0xFF065F46),
        ),
        scaffoldBackgroundColor: _scaffoldColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _appBarColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: darkBase.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceColor,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _accentGreen, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _accentGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentGreen,
            foregroundColor: const Color(0xFF06241A),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Gemini Chat in Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _ChatMessage {
  const _ChatMessage({
    this.text,
    required this.isUser,
    this.images = const [],
  });

  final String? text;
  final bool isUser;
  final List<GeminiImagePart> images;

  bool get hasText => (text ?? '').trim().isNotEmpty;
  bool get hasImages => images.isNotEmpty;
}

class _MyHomePageState extends State<MyHomePage> {
  final List<_ChatMessage> _messages =   [
    _ChatMessage(
      text: 'Hi! How can I help you',
      isUser: false,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final service = GeminiService.instance;
      final history = _buildGeminiContents();
      final reply = await service.sendMessage(contents: history);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: reply.text,
            images: reply.images,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gemini error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  List<Map<String, dynamic>> _buildGeminiContents() {
    return _messages
        .map((message) {
          final parts = <Map<String, dynamic>>[];
          if (message.hasText) {
            parts.add({
              'text': message.text!.trim(),
            });
          }
          if (message.hasImages) {
            for (final image in message.images) {
              parts.add({
                'inline_data': {
                  'data': base64Encode(image.bytes),
                  'mime_type': image.mimeType,
                },
              });
            }
          }
          return {
            'role': message.isUser ? 'user' : 'model',
            'parts': parts,
          };
        })
        .where((entry) => (entry['parts'] as List).isNotEmpty)
        .toList();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessage(BuildContext context, _ChatMessage message) {
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? _accentGreen : _surfaceColor;
    final textColor = isUser ? const Color(0xFF031B12) : Colors.white;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.hasText)
                    Text(
                      message.text!,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                height: 1.4,
                              ),
                    ),
                  if (message.hasText && message.hasImages)
                    const SizedBox(height: 12),
                  if (message.hasImages)
                    ...message.images.map(
                      (image) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.memory(
                              image.bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: _appBarColor.withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Colors.white12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Message the assistant…',
                  suffixIcon: Icon(Icons.auto_awesome, color: _accentGreen),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: _isSending ? null : _handleSend,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: _accentGreen,
                  foregroundColor: const Color(0xFF032015),
                  shape: const CircleBorder(),
                  elevation: 4,
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(context, _messages[index]),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }
}
