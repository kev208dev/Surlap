import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 우선순위(1~3)별 색상. 0(없음)은 보조 텍스트색.
Color todoPriorityColor(int priority, SpaceHourColors sh) {
  switch (priority) {
    case 1:
      return const Color(0xFFE0564A); // 빨강 (높음)
    case 2:
      return const Color(0xFFE8943A); // 주황 (보통)
    case 3:
      return const Color(0xFF4A90D9); // 파랑 (낮음)
    default:
      return sh.inkSoft;
  }
}
