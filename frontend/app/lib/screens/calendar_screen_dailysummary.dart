import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/diary.dart';

class CalendarDailySummaryDialog extends StatelessWidget {
  const CalendarDailySummaryDialog({
    super.key,
    required this.selectedDate,
    required this.diary,
  });

  final DateTime selectedDate;
  final Diary? diary;

  @override
  Widget build(BuildContext context) {
    final title = '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: '닫기',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (diary == null)
                      _EmptyDiaryCard(selectedDate: selectedDate)
                    else
                      _DiarySummaryCard(diary: diary!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiarySummaryCard extends StatelessWidget {
  const _DiarySummaryCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final emotionColor = _hexToColor(diary.colorHex) ?? const Color(0xFFEEF1F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: emotionColor.withOpacity(0.22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '대표 감정: ${diary.emotion}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '일기 요약',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          diary.summary,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _EmptyDiaryCard extends StatelessWidget {
  const _EmptyDiaryCard({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${selectedDate.month}월 ${selectedDate.day}일의 일기 데이터가 아직 없어요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

Color? _hexToColor(String value) {
  final hex = value.replaceFirst('#', '').trim();
  if (hex.length != 6 && hex.length != 8) {
    return null;
  }

  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return null;
  }

  return Color(parsed);
}