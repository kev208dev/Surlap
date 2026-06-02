import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/view_provider.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';
import '../../utils/screenshot_util.dart' show screenshotKey;

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final events = ref.watch(eventsProvider);
    final sh = context.sh;
    final year = view.viewYear;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        return _MiniMonthCard(
          year: year,
          month: month,
          events: events,
          sh: sh,
          onTap: (source) => _zoomToMonth(context, ref, source, year, month, sh),
        );
      },
    );
  }
}

class _MiniMonthCard extends StatelessWidget {
  final int year, month;
  final Map<String, List<dynamic>> events;
  final SpaceHourColors sh;
  final void Function(Rect source) onTap;

  const _MiniMonthCard({
    required this.year, required this.month,
    required this.events, required this.sh, required this.onTap,
  });

  static const _dow = ['일','월','화','수','목','금','토'];
  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return GestureDetector(
      onTap: () {
        final box = context.findRenderObject();
        final rect = box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.zero;
        onTap(rect);
      },
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(14),
          border: isCurrentMonth
              ? Border.all(color: sh.accent, width: 1.5)
              : Border.all(color: sh.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 월 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isCurrentMonth ? sh.accentBg : sh.card2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Center(
                child: Text(
                  _monthNames[month - 1],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrentMonth ? sh.accentInk : sh.inkSoft,
                  ),
                ),
              ),
            ),
            // 미니 캘린더 그리드
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
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
          // 요일 헤더
          Row(
            children: List.generate(7, (i) => Expanded(
              child: Center(
                child: Text(_dow[i],
                    style: TextStyle(fontSize: 7, color: sh.inkFaint)),
              ),
            )),
          ),
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
                      final key = du.toDateKey(DateTime(year, month, day));
                      final hasEvent = (events[key] ?? []).isNotEmpty;
                      final isToday = year == now.year &&
                          month == now.month && day == now.day;
                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 14, height: 14,
                            decoration: isToday ? BoxDecoration(
                              color: sh.accentBg,
                              shape: BoxShape.circle,
                            ) : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    color: isToday ? sh.accentInk : sh.ink,
                                    fontWeight: isToday
                                        ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: 3, height: 3,
                                      decoration: BoxDecoration(
                                        color: sh.accent,
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

// ── 년→월 줌(히어로 유사) 전환 ──────────────────────────────
// 뷰 전환이 Navigator 라우트가 아니라 AnimatedSwitcher 기반이라 실제 Hero 대신,
// 탭한 미니 월을 콘텐츠 영역으로 확대하는 오버레이를 띄운다. 시작과 동시에 뷰를
// 월간으로 전환해 두고, 끝에서 페이드아웃하며 실제 월간 뷰를 드러낸다.
void _zoomToMonth(BuildContext context, WidgetRef ref, Rect source,
    int year, int month, SpaceHourColors sh) {
  void switchView() {
    ref.read(viewProvider.notifier).setYearMonth(year, month);
    ref.read(viewProvider.notifier).setMode(ViewMode.events);
  }

  if (source == Rect.zero) {
    switchView();
    return;
  }
  final overlayState = Overlay.of(context);
  final box = screenshotKey.currentContext?.findRenderObject();
  final target = (box is RenderBox && box.hasSize)
      ? box.localToGlobal(Offset.zero) & box.size
      : Offset.zero & MediaQuery.of(context).size;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ZoomOverlay(
      source: source,
      target: target,
      sh: sh,
      monthLabel: '$month월',
      onSwitch: switchView,
      onDone: () => entry.remove(),
    ),
  );
  overlayState.insert(entry);
}

class _ZoomOverlay extends StatefulWidget {
  final Rect source, target;
  final SpaceHourColors sh;
  final String monthLabel;
  final VoidCallback onSwitch;
  final VoidCallback onDone;
  const _ZoomOverlay({
    required this.source, required this.target, required this.sh,
    required this.monthLabel, required this.onSwitch, required this.onDone,
  });
  @override
  State<_ZoomOverlay> createState() => _ZoomOverlayState();
}

class _ZoomOverlayState extends State<_ZoomOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSwitch(); // 월간 뷰를 아래에서 미리 빌드
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final rect = Rect.lerp(widget.source, widget.target, t)!;
        final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: Opacity(opacity: fade, child: _card(sh)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(SpaceHourColors sh) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sh.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: sh.accentBg,
            child: Center(
              child: Text(widget.monthLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sh.accentInk)),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
