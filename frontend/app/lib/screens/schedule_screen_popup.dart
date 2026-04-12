import 'dart:ui';

import 'package:flutter/material.dart';
import '../data/schedule.dart';

class ScheduleDailyDialog extends StatelessWidget {
  const ScheduleDailyDialog({
    super.key,
    required this.selectedDate,
    required this.schedules,
  });

  final DateTime selectedDate;
  final List<ScheduleModel> schedules;

  @override
  Widget build(BuildContext context) {
    final title =
        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                    if (schedules.isEmpty)
                      _EmptyScheduleCard(selectedDate: selectedDate)
                    else
                      _ScheduleListCard(schedules: schedules),
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

class _ScheduleListCard extends StatelessWidget {
  const _ScheduleListCard({required this.schedules});

  final List<ScheduleModel> schedules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < schedules.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ScheduleItem(schedule: schedules[i]),
        ],
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({required this.schedule});

  final ScheduleModel schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                schedule.isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: schedule.isDone
                    ? Colors.deepPurple
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: schedule.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
              ),
            ],
          ),
          if (schedule.description != null &&
              schedule.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              schedule.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.selectedDate});

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
        '${selectedDate.month}월 ${selectedDate.day}일에 등록된 일정이 없어요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
