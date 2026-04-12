import 'package:flutter/material.dart';

import '../data/schedule.dart';
import '../data/schedule_api_service.dart';
import 'schedule_screen_popup.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const int _basePage = 1200;
  late final PageController _pageController;
  int _currentPage = _basePage;

  // date → list of schedules
  Map<DateTime, List<ScheduleModel>> _schedulesByDate = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _basePage);
    _loadSchedules(_monthByPage(_basePage));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthByPage(int page) {
    final today = DateTime.now();
    return DateTime(today.year, today.month + (page - _basePage));
  }

  Future<void> _loadSchedules(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final list = await ScheduleApiService.fetchSchedulesByMonth(
        userId: 1, // TODO: 실제 사용자 ID로 교체
        year: month.year,
        month: month.month,
      );

      final Map<DateTime, List<ScheduleModel>> byDate = {};
      for (final s in list) {
        final parts = s.dueDate.split('-');
        if (parts.length != 3) continue;
        final key = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        byDate.putIfAbsent(key, () => []).add(s);
      }

      if (mounted) {
        setState(() => _schedulesByDate = byDate);
      }
    } catch (_) {
      // 조회 실패 시 빈 상태 유지
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _moveMonth(int delta) {
    final targetPage = _currentPage + delta;
    return _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openScheduleDetail(DateTime date) async {
    if (!mounted) return;

    List<ScheduleModel> schedules = [];
    try {
      schedules = await ScheduleApiService.fetchSchedulesByDate(
        userId: 1, // TODO: 실제 사용자 ID로 교체
        date: date,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 정보를 불러오는 중 오류가 발생했어요.')),
      );
      return;
    }

    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '일정 닫기',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => ScheduleDailyDialog(
        selectedDate: date,
        schedules: schedules,
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = _monthByPage(_currentPage);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              // 월 이동 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '이전 달',
                    onPressed: () => _moveMonth(-1),
                  ),
                  Text(
                    '${currentMonth.year}년 ${currentMonth.month}월',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '다음 달',
                    onPressed: () => _moveMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const _WeekdayHeader(),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 310,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          clipBehavior: Clip.none,
                          controller: _pageController,
                          onPageChanged: (page) {
                            setState(() => _currentPage = page);
                            _loadSchedules(_monthByPage(page));
                          },
                          itemBuilder: (context, page) {
                            final month = _monthByPage(page);
                            return _ScheduleMonthGrid(
                              month: month,
                              schedulesByDate: _schedulesByDate,
                              onDateTap: _openScheduleDetail,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 14),
              const _ScheduleHintCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _weekdays
            .map(
              (day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ScheduleMonthGrid extends StatelessWidget {
  const _ScheduleMonthGrid({
    required this.month,
    required this.schedulesByDate,
    required this.onDateTap,
  });

  final DateTime month;
  final Map<DateTime, List<ScheduleModel>> schedulesByDate;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmptyCount = firstDay.weekday % 7;
    final totalCells = ((leadingEmptyCount + dayCount) / 7).ceil() * 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          if (index < leadingEmptyCount ||
              index >= leadingEmptyCount + dayCount) {
            return const SizedBox.shrink();
          }

          final day = index - leadingEmptyCount + 1;
          final date = DateTime(month.year, month.month, day);
          final daySchedules = schedulesByDate[date] ?? [];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDateTap(date),
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: daySchedules.isNotEmpty
                      ? const Color(0xFFEDEBFF)
                      : const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDE1EA)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                      ),
                      if (daySchedules.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final s in daySchedules.take(2))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 9,
                                          color: Colors.deepPurple.shade700,
                                        ),
                                  ),
                                ),
                              if (daySchedules.length > 2)
                                Text(
                                  '+${daySchedules.length - 2}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 9,
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleHintCard extends StatelessWidget {
  const _ScheduleHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        '날짜를 탭하면 해당 날의 일정을 자세히 볼 수 있어요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
