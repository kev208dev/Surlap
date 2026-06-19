import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../i18n/strings.dart';
import '../providers/view_provider.dart';

/// 통합 뷰 전환 세그먼트(연·월·주·일). 월/연/주/일 헤더가 공유.
/// 2026 리디자인: 흐린 accent 트랙 + 흰 썸(다크는 짙은 자주) + accent 텍스트.
class ViewSegmentControl extends ConsumerWidget {
  const ViewSegmentControl({super.key});

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final dark = sh.dark;
    final mode = ref.watch(viewProvider).mode;
    final n = ref.read(viewProvider.notifier);

    final items = <(String, ViewMode, VoidCallback)>[
      ('연', ViewMode.year, () => n.setMode(ViewMode.year)),
      ('월', ViewMode.events, () => n.setMode(ViewMode.events)),
      ('주', ViewMode.planner, () => n.setWeekView(_todayKey())),
      ('일', ViewMode.day, () => n.setDayView(_todayKey())),
    ];
    final modes = items.map((e) => e.$2).toList();
    final activeIdx = modes.indexOf(mode);

    final accent = dark ? const Color(0xFFA99FF8) : const Color(0xFF5A2DF4);
    final track = dark
        ? const Color(0xFF8B6CFF).withValues(alpha: 0.12)
        : const Color(0xFF5A2DF4).withValues(alpha: 0.07);
    final thumb = dark ? const Color(0xFF2A2740) : Colors.white;
    final inactive = dark
        ? Colors.white.withValues(alpha: 0.5)
        : sh.ink.withValues(alpha: 0.45);

    return LayoutBuilder(builder: (context, c) {
      const padding = 4.0;
      final innerW = c.maxWidth - padding * 2;
      final cellW = innerW / items.length;

      return Container(
        height: 38,
        padding: const EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            if (activeIdx >= 0)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: cellW * activeIdx,
                top: 0,
                bottom: 0,
                width: cellW,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumb,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A2DF4).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                for (final (label, m, onTap) in items)
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: mode == m ? accent : inactive,
                          ),
                          child: Text(tr(label)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
