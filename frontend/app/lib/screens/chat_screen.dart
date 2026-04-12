import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../data/diary_api_service.dart';
import '../data/schedule_api_service.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _chatApiUrl =
      'https://helloguddn-emotion-calendar-app.hf.space/chat';
  static const String _dailySummaryApiUrl =
      'https://helloguddn-emotion-calendar-app.hf.space/daily-summary';

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

        final botText = (json['chat'] as String?)?.trim();

        final emotionData = json['emotion_data'] as Map<String, dynamic>?;
        final emotion = (emotionData?['label'] as String?)?.trim();
        final colorHex = (emotionData?['color'] as String?)?.trim();

        const int userId = 1; // TODO: 실제 사용자 ID로 교체
        final action = json['action'] as Map<String, dynamic>?;
        final shouldSaveDiary = action?['save_diary'] == true;

        if (shouldSaveDiary && emotion != null && colorHex != null) {
          final summary = await _requestDailySummary(messagesPayload);
          DiaryApiService.saveDiary(
            userId: userId,
            date: DateTime.now(),
            messages: messagesPayload
                .map((m) => Map<String, dynamic>.from(m))
                .toList(),
            summary: summary.isEmpty ? null : summary,
            emotion: emotion,
            color: colorHex,
          ).catchError((_) => null);
        }

        final addSchedule = action?['add_schedule'] as Map<String, dynamic>?;
        if (addSchedule != null) {
          final title = addSchedule['title'] as String?;
          final details = addSchedule['details'] as String?;
          final dueDate = addSchedule['due_date'] as String?;
          if (title != null && dueDate != null) {
            ScheduleApiService.saveSchedule(
              userId: userId,
              title: title,
              description: details,
              dueDate: dueDate,
            ).catchError((_) => null);
          }
        }

        setState(() {
          _messages.add(
            _ChatMessage(
              text: (botText == null || botText.isEmpty)
                  ? '응답을 받지 못했어요. 다시 시도해 주세요.'
                  : botText,
              isMine: false,
              emotion: emotion,
              colorHex: colorHex,
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

  Future<String> _requestDailySummary(
    List<Map<String, String>> messagesPayload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_dailySummaryApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messagesPayload}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return '';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['summary'] as String?)?.trim() ?? '';
    } catch (_) {
      return '';
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemBuilder: (context, index) {
              final message = _messages[index];
              final bubbleColor = message.isMine
                  ? Colors.deepPurple.shade100
                  : _colorFromHex(message.colorHex).withOpacity(0.18);

              return Align(
                alignment: message.isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _BubbleWithTail(
                  isMine: message.isMine,
                  color: bubbleColor,
                  child: MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16),
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

class _BubbleWithTail extends StatelessWidget {
  const _BubbleWithTail({
    required this.isMine,
    required this.color,
    required this.child,
  });

  final bool isMine;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(isMine: isMine, color: color),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 0 : 8,
          right: isMine ? 8 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.isMine, required this.color});

  final bool isMine;
  final Color color;

  static const double _radius = 14;
  static const double _tailWidth = 8;
  static const double _tailHeight = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0x12000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = _buildPath(size);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = _radius;
    final tw = _tailWidth;
    final th = _tailHeight;

    final path = Path();

    if (isMine) {
      // 오른쪽 상단 꼬리 (말풍선 바깥 오른쪽으로 튀어나옴)
      path.moveTo(r, 0);
      path.lineTo(w, 0);
      path.lineTo(w + tw, -th); // 꼬리 끝
      path.lineTo(w, r);
      path.lineTo(w, h - r);
      path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    } else {
      // 왼쪽 상단 꼬리 (말풍선 바깥 왼쪽으로 튀어나옴)
      path.moveTo(0, r);
      path.lineTo(-tw, -th); // 꼬리 끝
      path.lineTo(0, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
      path.lineTo(w, h - r);
      path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.isMine != isMine || oldDelegate.color != color;
}