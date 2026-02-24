import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _chatApiUrl =
      'https://helloguddn-emotion-calendar-app.hf.space/chat';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: '안녕하세요! 오늘은 무슨 일이 있으셨나요?',
      isMine: false,
      emotion: '중립',
      colorHex: '#FFFFFF',
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: text, isMine: true));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final messagesPayload = _messages
          .map((message) => {
                'role': message.isMine ? 'user' : 'assistant',
                'content': message.text,
              })
          .toList();

      final response = await http.post(
        Uri.parse(_chatApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messagesPayload}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        final botText = (json['response'] as String?)?.trim();
        final emotion = (json['emotion'] as String?)?.trim();
        final colorHex = (json['color'] as String?)?.trim();

        setState(() {
          _messages.add(
            _ChatMessage(
              text: (botText == null || botText.isEmpty)
                  ? '응답을 받지 못했어요. 다시 시도해 주세요.'
                  : botText,
              isMine: false,
              emotion: (emotion == null || emotion.isEmpty) ? null : emotion,
              colorHex: (colorHex == null || colorHex.isEmpty) ? null : colorHex,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(const _ChatMessage(
            text: '서버와 통신 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
            isMine: false,
          ));
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(const _ChatMessage(
          text: '네트워크 오류가 발생했어요. 인터넷 연결을 확인해 주세요.',
          isMine: false,
        ));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) {
      return Colors.white;
    }

    var value = hex.replaceFirst('#', '').trim();
    if (value.length == 6) {
      value = 'FF$value';
    }

    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return Colors.white;
    }
    return Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemBuilder: (context, index) {
              final message = _messages[index];
              final bubbleColor = message.isMine
                  ? Colors.deepPurple.shade100
                  : _colorFromHex(message.colorHex).withOpacity(0.18);

              return Align(
                alignment: message.isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarkdownBody(
                          data: message.text,
                          selectable: true, // 텍스트 선택 가능 여부
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16),
                          ),
                        ),
                        // if (!message.isMine &&
                        //     message.emotion != null &&
                        //     message.emotion!.isNotEmpty) ...[
                        //   const SizedBox(height: 6),
                        //   Text(
                        //     '감정: ${message.emotion}',
                        //     style: Theme.of(context)
                        //         .textTheme
                        //         .bodySmall
                        //         ?.copyWith(fontWeight: FontWeight.w600),
                        //   ),
                        // ],
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: _messages.length,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _isSending ? '응답을 기다리는 중...' : '메시지를 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMine,
    this.emotion,
    this.colorHex,
  });

  final String text;
  final bool isMine;
  final String? emotion;
  final String? colorHex;
}