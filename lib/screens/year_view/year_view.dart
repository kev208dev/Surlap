import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../providers/view_provider.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';

// 연간 미니 월 카드 라운드(홈·캘린더 톤과 통일).
const double _yRadius = 18;

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final events = ref.watch(eventsProvider);
    final sh = context.sh;
    final year = view.viewYear;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: Gap.sm,
        mainAxisSpacing: Gap.sm,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        return _MiniMonthCard(
          year: year,
          month: month,
          events: events,
          sh: sh,
          // 줌 애니메이션 없이 곧바로 월간으로 전환.
          onTap: () {
            ref.read(viewProvider.notifier).setYearMonth(year, month);
            ref.read(viewProvider.notifier).setMode(ViewMode.events);
          },
        );
      },
    );
  }
}

// ── 미니 월 카드 ────────────────────────────────────────────────────

class _MiniMonthCard extends StatelessWidget {
  final int year, month;
  final Map<String, List<dynamic>> events;
  final SpaceHourColors sh;
  final VoidCallback onTap;

  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.events,
    required this.sh,
    required this.onTap,
  });

  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(_yRadius),
          border: isCurrentMonth
              ? Border.all(color: sh.accent, width: 1.5)
              : Border.all(color: sh.ink.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: sh.dark ? 0.28 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 월 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentMonth
                    ? sh.accent.withValues(alpha: 0.12)
                    : sh.card2,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(_yRadius)),
              ),
              child: Center(
                child: Text(
                  _monthNames[month - 1],
                  style: AppType.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCurrentMonth ? sh.accent : sh.inkSoft,
                  ),
                ),
              ),
            ),
            // 미니 캘린더 그리드 (이벤트 dot 포함)
            Expanded(
              child: _MiniMonthGrid(
                year: year,
                month: month,
                sh: sh,
                events: events,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공유 미니 그리드 위젯 ─────────────────────────────────────────────
// _MiniMonthCard(년 뷰)와 _ZoomOverlay(전환 중) 양쪽에서 재사용.

class _MiniMonthGrid extends StatelessWidget {
  final int year, month;
  final SpaceHourColors sh;
  /// null이면 이벤트 dot 표시 안 함 (줌 오버레이에서 사용).
  final Map<String, List<dynamic>>? events;

  const _MiniMonthGrid({
    required this.year,
    required this.month,
    required this.sh,
    this.events,
  });

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    // 일요일 시작
    final startOffset = first.weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final cells = startOffset + daysInMonth;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          // 요일 헤더 (일=빨강, 토=파랑 살짝)
          Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(_dow[i],
                      style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: i == 0
                              ? sh.sun.withValues(alpha: 0.7)
                              : i == 6
                                  ? sh.sat.withValues(alpha: 0.7)
                                  : sh.inkFaint)),
                ),
              ),
            ),
          ),
          // 날짜 셀
          Expanded(
            child: Column(
              children: List.generate(rows, (r) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (c) {
                      final idx = r * 7 + c;
                      final day = idx - startOffset + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const Expanded(child: SizedBox());
                      }
                      final key =
                          du.toDateKey(DateTime(year, month, day));
                      final hasEvent =
                          events != null && (events![key] ?? []).isNotEmpty;
                      final isToday = year == now.year &&
                          month == now.month &&
                          day == now.day;
                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: isToday
                                ? BoxDecoration(
                                    color: sh.accent,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    color: isToday ? Colors.white : sh.ink,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: isToday ? 1 : 0,
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color:
                                            isToday ? Colors.white : sh.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
