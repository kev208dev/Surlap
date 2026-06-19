import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// 연/월/주 이동 — 두 셰브론이 가는 디바이더로 이어진 하나의 알약.
/// 분리 버튼 대신 핀치 형태로 시각적 응집성 강조.
class ArrowPinch extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String? prevTooltip;
  final String? nextTooltip;
  const ArrowPinch({
    super.key,
    required this.onPrev,
    required this.onNext,
    this.prevTooltip,
    this.nextTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final dark = sh.dark;
    final chev = dark ? const Color(0xFFC9B6F0) : const Color(0xFF5A2DF4);
    final bg = dark
        ? const Color(0xFF24222E)
        : Colors.white.withValues(alpha: 0.72);
    final divider = dark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFF14131A).withValues(alpha: 0.08);

    Widget btn(IconData icon, VoidCallback onTap, String? tooltip) {
      final child = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(icon, size: 22, color: chev),
        ),
      );
      return tooltip != null ? Tooltip(message: tooltip, child: child) : child;
    }

    return Container(
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: dark
            ? null
            : Border.all(
                color: const Color(0xFF14131A).withValues(alpha: 0.05)),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF4A1FD0).withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -10,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.chevron_left_rounded, onPrev, prevTooltip),
          Container(width: 1, height: 20, color: divider),
          btn(Icons.chevron_right_rounded, onNext, nextTooltip),
        ],
      ),
    );
  }
}
