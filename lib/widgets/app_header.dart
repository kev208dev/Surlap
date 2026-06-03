import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';
import '../screens/search_view.dart';

// ─── 서브 헤더 (날짜 앵커) ────────────────────────────────────────
// 월간/연간에서만 표시. 주간/일간은 자체 헤더, 그 외 뷰는 자체 제목.
// 오늘 버튼·뷰 세그먼트·날짜 피커는 제거됨(전환은 상단바 점세개로).
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final isYear = view.mode == ViewMode.year;
    final isMonth = view.mode == ViewMode.events;

    // 앵커는 월간/연간에서만. (주간/일간/홈/스케줄표/테마/프로필 등은 숨김)
    if (!isMonth && !isYear) return const SizedBox.shrink();

    return Container(
      color: sh.bg,
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.lg, Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 날짜 라벨 탭 → 오늘로 이동 ("2026년"은 그대로, 월만 크게)
          GestureDetector(
            onTap: () {
              notifier.goToToday();
              if (isYear) notifier.setMode(ViewMode.events);
            },
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${view.viewYear}년',
                    style: AppType.title.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: sh.inkSoft),
                  ),
                  if (!isYear)
                    TextSpan(
                      text: ' ${_monthNames[view.viewMonth - 1]}',
                      style: AppType.title.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: sh.ink),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // 검색
          _IconBtn(
            icon: Icons.search_rounded,
            sh: sh,
            onTap: () => showSearchSheet(context),
          ),
          // 월/년 이동 화살표
          _NavBtn(
            label: '＜',
            onTap: isYear ? notifier.prevYear : notifier.prevMonth,
            sh: sh,
          ),
          _NavBtn(
            label: '＞',
            onTap: isYear ? notifier.nextYear : notifier.nextMonth,
            sh: sh,
          ),
        ],
      ),
    );
  }
}

// ─── 탐색 화살표 버튼 ────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn({required this.label, required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(label,
            style: AppType.section.copyWith(
                fontWeight: FontWeight.w500, color: sh.inkSoft)),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _IconBtn({required this.icon, required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 22, color: sh.inkSoft),
      ),
    );
  }
}
