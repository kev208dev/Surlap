import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// 캘린더 뷰 세그먼트 — 연/월/주/일 한 줄 토글.
/// 활성 썸: 흰색(라이트) / 짙은 자주(다크) + 텍스트 accent.
class ViewSegment extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  const ViewSegment({
    super.key,
    required this.index,
    required this.onChanged,
    this.labels = const ['연', '월', '주', '일'],
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final dark = sh.dark;
    final accent = dark ? const Color(0xFFA99FF8) : const Color(0xFF5A2DF4);
    final track = dark
        ? const Color(0xFF8B6CFF).withValues(alpha: 0.12)
        : const Color(0xFF5A2DF4).withValues(alpha: 0.07);
    final thumb = dark ? const Color(0xFF2A2740) : Colors.white;
    final inactive = dark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF14131A).withValues(alpha: 0.45);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? thumb : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: index == i
                        ? [
                            BoxShadow(
                              color: const Color(0xFF5A2DF4)
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: index == i ? accent : inactive,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
