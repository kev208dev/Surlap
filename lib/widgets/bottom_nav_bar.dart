import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart' as du;
import '../providers/view_provider.dart';
import '../widgets/sidebar_drawer.dart';
import 'coach_mark.dart';

// ─── Floating Pill Bottom Navigation ────────────────────────────
// 화면 중앙에 떠 있는 작은 capsule 형태. 아이콘만 표시.
// Active: 흰 pill 안에 어두운 아이콘 / Inactive: 흐린 아이콘
class SpaceHourBottomNav extends ConsumerWidget {
  const SpaceHourBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view     = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final sh       = context.sh;

    String todayKey() => du.toDateKey(DateTime.now());

    // ── 탭 정의 ────────────────────────────────────────────────
    final tabs = [
      _Tab(
        active: Icons.home_rounded,
        inactive: Icons.home_outlined,
        label: '홈',
        isActive: view.mode == ViewMode.home,
        onTap: () => notifier.setMode(ViewMode.home),
      ),
      _Tab(
        active: Icons.calendar_month_rounded,
        inactive: Icons.calendar_month_outlined,
        label: '캘린더',
        isActive: const {ViewMode.events, ViewMode.year, ViewMode.planner}.contains(view.mode),
        onTap: () {
          if (!const {ViewMode.events, ViewMode.year, ViewMode.planner}.contains(view.mode)) {
            notifier.setMode(ViewMode.events);
          }
        },
      ),
      _Tab(
        active: Icons.grid_view_rounded,
        inactive: Icons.grid_view_outlined,
        label: '시간표',
        isActive: view.mode == ViewMode.timetable,
        onTap: () => notifier.setMode(ViewMode.timetable),
        coachKey: coachKeyTabTimetable,
      ),
      _Tab(
        active: Icons.edit_note_rounded,
        inactive: Icons.edit_note_rounded,
        label: '기록',
        isActive: view.mode == ViewMode.day,
        onTap: () => notifier.setDayView(todayKey()),
      ),
      _Tab(
        active: Icons.settings_rounded,
        inactive: Icons.settings_outlined,
        label: '설정',
        isActive: false,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const FractionallySizedBox(
            heightFactor: 0.85,
            child: SidebarDrawer(),
          ),
        ),
        coachKey: coachKeyTabProfile,
      ),
    ];

    // ── 컨테이너 색상 (다크/라이트 분기) ─────────────────────
    final containerColor = sh.dark
        ? Colors.black.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = sh.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.70);
    final shadowColor = Colors.black.withValues(alpha: sh.dark ? 0.45 : 0.14);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: SafeArea(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                key: coachKeyBottomNav,
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: tabs.map((t) => _NavBtn(
                    tab: t,
                    dark: sh.dark,
                    // 라이트 다크 모두 accent 색 힌트를 미사용 — 흰 pill로 통일
                  )).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 탭 데이터 모델 ──────────────────────────────────────────────
class _Tab {
  final IconData active;
  final IconData inactive;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final GlobalKey? coachKey;

  const _Tab({
    required this.active,
    required this.inactive,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.coachKey,
  });
}

// ─── 개별 탭 버튼 ────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final _Tab tab;
  final bool dark;

  const _NavBtn({required this.tab, required this.dark});

  @override
  Widget build(BuildContext context) {
    final active = tab.isActive;

    // Active pill: 항상 흰색 → 라이트/다크 모두 선명하게
    const activePillColor = Colors.white;
    final activeIconColor = dark ? Colors.black87 : Colors.black;
    final inactiveIconColor = dark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.40);

    return Semantics(
      label: tab.label,
      button: true,
      child: GestureDetector(
        key: tab.coachKey,
        onTap: tab.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 54,
          height: 58,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: active ? 46 : 38,
              height: active ? 42 : 38,
              decoration: BoxDecoration(
                color: active ? activePillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(23),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.22 : 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                active ? tab.active : tab.inactive,
                size: 22,
                color: active ? activeIconColor : inactiveIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
