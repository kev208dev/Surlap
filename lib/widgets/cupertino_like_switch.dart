import 'package:flutter/material.dart';

/// iOS Settings 감성 토글 — ON=accent + soft glow, OFF=중성 회색.
/// 설정 행에서 Switch.adaptive 대신 사용. 시각만 — semantics 는 라벨로 별도.
class CupertinoLikeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  const CupertinoLikeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final on = activeColor ?? const Color(0xFF5A2DF4);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? on : const Color(0x2114131A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: on.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
