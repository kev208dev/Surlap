import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/strings.dart';
import '../providers/view_provider.dart';

/// 통합 뷰 전환 세그먼트(연·월·주·일).
/// 월/연(AppHeader)·주(planner)·일(day) 헤더가 공유. 탭 1번으로 즉시 전환.
/// 활성 pill 이 좌우로 sliding — 대기업 iOS segment 와 동일한 인지 모델.
class ViewSegmentControl extends ConsumerWidget {
  const ViewSegmentControl({super.key});

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
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

    return LayoutBuilder(builder: (context, c) {
      const padding = 3.0;
      final innerW = c.maxWidth - padding * 2;
      final cellW = innerW / items.length;

      return Container(
        height: 38,
        padding: const EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            // 활성 pill — sliding.
            if (activeIdx >= 0)
              AnimatedPositioned(
                duration: Motion.fast,
                curve: Motion.curve,
                left: cellW * activeIdx,
                top: 0,
                bottom: 0,
                width: cellW,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sh.accent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: sh.accent.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
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
                          duration: Motion.fast,
                          curve: Motion.curve,
                          style: AppType.label.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: mode == m
                                ? Colors.white
                                : sh.ink.withValues(alpha: 0.55),
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
