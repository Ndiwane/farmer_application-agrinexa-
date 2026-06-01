import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class AgriBotScreen extends StatefulWidget {
  final String? initialMessage;
  const AgriBotScreen({super.key, this.initialMessage});

  @override
  State<AgriBotScreen> createState() => _AgriBotScreenState();
}

class _AgriBotScreenState extends State<AgriBotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const String _serverUrl = 'http://13.63.87.27:3000';

  // Suggested quick questions
  static const List<String> _suggestions = [
    '🌿 Best crops for this season?',
    '💰 Current tomato prices in Douala?',
    '🚜 Tips for selling on AgriNexa?',
    '🌱 How to treat leaf blight?',
    '📦 How does delivery work?',
    '💳 How do I receive payments?',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'assistant',
      'content':
          'Hello! 👋 I\'m AgriBot, your agricultural assistant.\n\nI can help you with:\n• Crop prices and market trends\n• Farming tips and disease treatment\n• How to buy and sell on AgriNexa\n• Payment and delivery questions\n\nHow can I help you today?',
    });
    // Auto-send initial message if provided (from quick questions)
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text.trim()});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Build messages for API (exclude welcome message from history)
      final apiMessages = _messages
          .where((m) => !(m['role'] == 'assistant' &&
              m['content']!.contains('I\'m AgriBot')))
          .map((m) => {'role': m['role'], 'content': m['content']})
          .toList();

      final response = await http.post(
        Uri.parse('$_serverUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': apiMessages}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['reply'] ?? 'Sorry, I could not process that.',
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ Sorry, I\'m having trouble right now. Please try again.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ Connection error. Please check your internet and try again.',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AgriBot',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Text('AI Agricultural Assistant',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content':
                      'Hello! 👋 I\'m AgriBot, your agricultural assistant.\n\nHow can I help you today?',
                });
              });
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading bubble
                if (_isLoading && index == _messages.length) {
                  return _TypingIndicator();
                }

                final message = _messages[index];
                final isBot = message['role'] == 'assistant';
                return _ChatBubble(
                  text: message['content'] ?? '',
                  isBot: isBot,
                );
              },
            ),
          ),

          // Quick suggestions (show only when few messages)
          if (_messages.length <= 2)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _sendMessage(_suggestions[index]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLighter,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(_suggestions[index],
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_messages.length <= 2) const SizedBox(height: 8),

          // Input bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask AgriBot anything...',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppColors.textLight
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isBot;

  const _ChatBubble({required this.text, required this.isBot});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isBot) ...[
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isBot
                      ? Theme.of(context).appBarTheme.backgroundColor
                      : AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isBot ? 4 : 16),
                    bottomRight: Radius.circular(isBot ? 16 : 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isBot ? AppColors.textDark : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(reverse: true),
    );
    _animations = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controllers[i],
          curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _animations[i],
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                              0.3 + (_animations[i].value * 0.7)),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}