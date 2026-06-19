import 'package:flutter/material.dart';

/// 위젯 / 타임라인에서 공유하는 교시 세그먼트 바.
/// - 과거: 어둑한 색, 현재: 라벤더 accent + 가운데 흰 플레이헤드, 미래: 주얼톤 팔레트.
class PeriodBar extends StatelessWidget {
  final List<Color> segments;
  final int currentIndex; // -1 이면 진행 중 교시 없음
  final double height;
  const PeriodBar({
    super.key,
    required this.segments,
    required this.currentIndex,
    this.height = 20,
  });

  /// 미래 교시 기본 팔레트(과목 색이 따로 없을 때).
  static const jewelPalette = <Color>[
    Color(0xFF3A3A78),
    Color(0xFF2F4E7A),
    Color(0xFF1F5A5A),
    Color(0xFF243A6E),
    Color(0xFF3E2E72),
    Color(0xFF5A2E62),
    Color(0xFF5A2E4E),
  ];

  static const activeColor = Color(0xFFA98BFF);

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return SizedBox(height: height);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              flex: i == currentIndex ? 17 : 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i == currentIndex ? activeColor : segments[i],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: i == currentIndex
                    ? const Center(
                        child: SizedBox(
                          width: 3,
                          child: ColoredBox(color: Colors.white),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
