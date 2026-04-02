// 캘린더가 보여지는 인터페이스
import 'package:flutter/material.dart';

import '../data/diary_api_service.dart';
import 'calendar_screen_dailysummary.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _basePage = 1200;
  late final PageController _pageController;
  int _currentPage = _basePage;

  late final Map<DateTime, Color> _emotionColorByDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _basePage);
    _emotionColorByDate = _buildMockEmotionColors();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<DateTime, Color> _buildMockEmotionColors() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month);
    return {
      DateTime(base.year, base.month, 1): const Color(0xFFFFCC80),
      DateTime(base.year, base.month, 2): const Color(0xFF81D4FA),
      DateTime(base.year, base.month, 3): const Color(0xFFA5D6A7),
      DateTime(base.year, base.month, 5): const Color(0xFFFFAB91),
      DateTime(base.year, base.month, 8): const Color(0xFFCE93D8),
      DateTime(base.year, base.month, 12): const Color(0xFF80CBC4),
      DateTime(base.year, base.month, 14): const Color(0xFFFFF59D),
      DateTime(base.year, base.month, 19): const Color(0xFFE6EE9C),
    };
  }

  DateTime _monthByPage(int page) {
    final today = DateTime.now();
    return DateTime(today.year, today.month + (page - _basePage));
  }

  Future<void> _moveMonth(int delta) {
    final targetPage = _currentPage + delta;
    return _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

    Future<void> _openDailySummary(DateTime date) async {
    if (!mounted) return;

    final diary = await DiaryApiService.fetchDiary(userId: 1, date: date);

    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '일기 요약 닫기',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return CalendarDailySummaryDialog(
          selectedDate: date,
          diary: diary,
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthHeader(
                  currentMonth: currentMonth,
                  onPreviousMonth: () => _moveMonth(-1),
                  onNextMonth: () => _moveMonth(1),
                ),
                const SizedBox(height: 8),
                const _WeekdayHeader(),
                const SizedBox(height: 6),
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, page) {
                      final month = _monthByPage(page);
                      return _MonthGrid(
                        month: month,
                        emotionColorByDate: _emotionColorByDate,
                        onDateTap: _openDailySummary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                const _LegendCard(),
                const SizedBox(height: 12),
                const _DiaryHintCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.currentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime currentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // child: Text(
      //   '${currentMonth.year}년 ${currentMonth.month}월',
      //   textAlign: TextAlign.center,
      //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
      //         fontWeight: FontWeight.w600,
      child: Row(
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전 달',
          ),
          Expanded(
            child: Text(
              '${currentMonth.year}년 ${currentMonth.month}월',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음 달',
          ),
        ],
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.emotionColorByDate,
    required this.onDateTap,
  });

  final DateTime month;
  final Map<DateTime, Color> emotionColorByDate;
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
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
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
          if (index < leadingEmptyCount || index >= leadingEmptyCount + dayCount) {
            return const SizedBox.shrink();
          }

          final day = index - leadingEmptyCount + 1;
          final date = DateTime(month.year, month.month, day);
          final color = emotionColorByDate[date];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDateTap(date),
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color ?? const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDE1EA)),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Color(0xFFFF4500), label: '분노'),
              _LegendItem(color: Color(0xFFFFA500), label: '기대'),
              _LegendItem(color: Color(0xFFFFFF00), label: '기쁨'),
              _LegendItem(color: Color(0xFF7FFF00), label: '신뢰'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Color(0xFF00FF00), label: '공포'),
              _LegendItem(color: Color(0xFF00FFFF), label: '놀람'),
              _LegendItem(color: Color(0xFF0000FF), label: '슬픔'),
              _LegendItem(color: Color(0xFF800080), label: '혐오'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCDD4E0)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DiaryHintCard extends StatelessWidget {
  const _DiaryHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '날짜를 탭하면 해당 일기의 감정 분석 결과를 자세히 볼 수 있어요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
