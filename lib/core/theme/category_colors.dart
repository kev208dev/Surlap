import 'package:flutter/material.dart';

/// 일정/루틴 카테고리용 색 팔레트.
///
/// 브랜드 보라 테마 시스템(app_theme.dart / color_presets.dart)과는 **완전히 별개**다.
/// 여기엔 카테고리 색만 정의하며 기존 테마는 건드리지 않는다.
///
/// 각 색은 다크/라이트 한 쌍으로 정의된다. 현재 테마 brightness에 맞는 값을
/// [CategoryColors.resolve]/[CategoryColors.byBrightness]가 돌려준다.
class CategoryColor {
  /// 영문 식별자(저장·배정에 사용). 예: 'Coral'.
  final String key;

  /// 다크 모드용 색.
  final Color dark;

  /// 라이트 모드용 색.
  final Color light;

  const CategoryColor(this.key, this.dark, this.light);

  /// brightness에 맞는 색.
  Color of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// 카테고리 색 팔레트(16색) + 해석/배정 헬퍼.
abstract final class CategoryColors {
  CategoryColors._();

  // ── 16색 정의 (영문 key / darkHex / lightHex) ──────────────────────
  // ■ 레드·핑크
  static const coral =
      CategoryColor('Coral', Color(0xFFFF6B6B), Color(0xFFFA5252));
  static const rose =
      CategoryColor('Rose', Color(0xFFFF7AA8), Color(0xFFE64980));
  static const magenta =
      CategoryColor('Magenta', Color(0xFFE64980), Color(0xFFC2255C));
  static const salmon =
      CategoryColor('Salmon', Color(0xFFFF9E80), Color(0xFFF76707));

  // ■ 오렌지·옐로우
  static const tangerine =
      CategoryColor('Tangerine', Color(0xFFFF922B), Color(0xFFE8590C));
  static const amber =
      CategoryColor('Amber', Color(0xFFFFC93C), Color(0xFFF59F00));
  static const lime =
      CategoryColor('Lime', Color(0xFFA9E34B), Color(0xFF74B816));
  static const olive =
      CategoryColor('Olive', Color(0xFFC0CA33), Color(0xFF9CAB0A));

  // ■ 그린·민트
  static const emerald =
      CategoryColor('Emerald', Color(0xFF51CF66), Color(0xFF2F9E44));
  static const teal =
      CategoryColor('Teal', Color(0xFF2DD4BF), Color(0xFF0CA678));
  static const mint =
      CategoryColor('Mint', Color(0xFF63E6BE), Color(0xFF12B886));
  static const cyan =
      CategoryColor('Cyan', Color(0xFF22D3EE), Color(0xFF0C8599));

  // ■ 블루·퍼플
  static const sky =
      CategoryColor('Sky', Color(0xFF4DABF7), Color(0xFF1C7ED6));
  static const indigo =
      CategoryColor('Indigo', Color(0xFF5C7CFA), Color(0xFF4263EB));
  static const violet =
      CategoryColor('Violet', Color(0xFF9775FA), Color(0xFF7048E8));
  static const lavender =
      CategoryColor('Lavender', Color(0xFFB197FC), Color(0xFF845EF7));

  /// key → 색. (직접 색을 고를 때 사용)
  static const Map<String, CategoryColor> byKey = {
    'Coral': coral,
    'Rose': rose,
    'Magenta': magenta,
    'Salmon': salmon,
    'Tangerine': tangerine,
    'Amber': amber,
    'Lime': lime,
    'Olive': olive,
    'Emerald': emerald,
    'Teal': teal,
    'Mint': mint,
    'Cyan': cyan,
    'Sky': sky,
    'Indigo': indigo,
    'Violet': violet,
    'Lavender': lavender,
  };

  /// 자동 배정용 정렬 순서(key 목록).
  ///
  /// 색 가문(red·orange·green·blue)을 라운드로빈으로 섞어, 비슷해서 헷갈리는
  /// 색끼리 서로 인접하지 않게 배치했다(최소 4칸 이상 간격):
  ///   - Emerald(2) ↔ Teal(6) ↔ Mint(10) ↔ Cyan(14)
  ///   - Sky(3) ↔ Indigo(7) ↔ Violet(11) ↔ Lavender(15)
  ///   - Coral(0) ↔ Rose(4) ↔ Magenta(8) ↔ Salmon(12)
  static const List<String> order = [
    'Coral', 'Tangerine', 'Emerald', 'Sky', // 라운드 1 (R·O·G·B)
    'Rose', 'Amber', 'Teal', 'Indigo', // 라운드 2
    'Magenta', 'Lime', 'Mint', 'Violet', // 라운드 3
    'Salmon', 'Olive', 'Cyan', 'Lavender', // 라운드 4
  ];

  /// [order] 순서의 색 객체 목록(팔레트 미리보기/스와치 그리드용).
  static List<CategoryColor> get palette =>
      [for (final k in order) byKey[k]!];

  // ── 해석(brightness → Color) ───────────────────────────────────────

  /// context의 현재 테마 brightness에 맞는 색. (예: CategoryColors.resolve(context, key))
  /// 잘못된 key면 첫 색(Coral)로 폴백.
  static Color resolve(BuildContext context, String key) =>
      byBrightness(Theme.of(context).brightness, key);

  /// brightness를 직접 받아 해석.
  static Color byBrightness(Brightness b, String key) =>
      (byKey[key] ?? coral).of(b);

  // ── 순차 배정(자동 다음 색) ────────────────────────────────────────

  /// i번째 색 key(순환). 일정/루틴을 추가 순서대로 색칠할 때 사용.
  static String keyForIndex(int i) => order[i % order.length];

  /// i번째 색 객체(순환).
  static CategoryColor forIndex(int i) => byKey[keyForIndex(i)]!;

  /// 이미 쓰인 key들([used])과 겹치지 않는 다음 색 key. 전부 쓰였으면 순환 배정.
  static String nextUnused(Iterable<String> used) {
    final set = used.toSet();
    for (final k in order) {
      if (!set.contains(k)) return k;
    }
    return keyForIndex(set.length);
  }
}
