import 'package:flutter/material.dart';

class ColorPreset {
  final String id;
  final String name;
  final Color dot;
  final Color accent;
  final Color accentInk;
  final Color accentBg;
  final Color app;
  final Color card;
  final Color card2;
  final Color hairline;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final bool dark;

  const ColorPreset({
    required this.id,
    required this.name,
    required this.dot,
    required this.accent,
    required this.accentInk,
    required this.accentBg,
    required this.app,
    required this.card,
    required this.card2,
    required this.hairline,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    this.dark = false,
  });
}

// 단일 프리셋: 라이트 라벤더 배경 + 브랜드 퍼플 액센트
const kBrandPurple = Color(0xFF5A2DF4);

// 배경 그라데이션 — Scaffold는 단색 → 최상위 Container(gradient) 로 깔기.
const kAppBgTopLight = Color(0xFFFBF9FE);
const kAppBgBottomLight = Color(0xFFF3F0FA);
const kAppBgTopDark = Color(0xFF15131F);
const kAppBgBottomDark = Color(0xFF0E0D14);

// 액센트 그라데이션(히어로 카드/액티브) 135°.
const kAccentGradLight = <Color>[
  Color(0xFF7B4BFF),
  Color(0xFF5A2DF4),
  Color(0xFF4A1FD0),
];
const kAccentGradDark = <Color>[
  Color(0xFF8257FF),
  Color(0xFF5A2DF4),
];

const kDefaultPreset = ColorPreset(
  id: 'light',
  name: 'Surlap',
  dot: kBrandPurple,
  accent: kBrandPurple,
  accentInk: Color(0xFF4A1FD0),
  // rgba(90,45,244,.10) — 액티브 알약/틴트 배경
  accentBg: Color(0x1A5A2DF4),
  app: kAppBgTopLight,                  // Scaffold 단색용 fallback
  card: Color(0xFFFFFFFF),
  card2: Color(0xFFF6F4FA),
  hairline: Color(0x0F14131A),          // rgba(20,19,26,.06)
  ink: Color(0xFF14131A),
  inkSoft: Color(0xFF6E6B7A),
  inkFaint: Color(0xFFA8A6B4),
  dark: false,
);

const kDarkPreset = ColorPreset(
  id: 'dark',
  name: 'Surlap Dark',
  dot: Color(0xFF8B6CFF),
  accent: Color(0xFF8B6CFF),
  accentInk: Color(0xFFC9B6F0),
  // rgba(139,108,255,.22) — 활성 알약 배경
  accentBg: Color(0x388B6CFF),
  app: kAppBgTopDark,
  card: Color(0xFF1A1A22),
  card2: Color(0xFF1B1926),
  hairline: Color(0x0FFFFFFF),
  ink: Color(0xFFF2F2F6),
  inkSoft: Color(0xFFADADBC),
  inkFaint: Color(0xFF6E6E7C),
  dark: true,
);

// presetById 호출 코드 하위 호환용
ColorPreset presetById(String id) => id == 'dark' ? kDarkPreset : kDefaultPreset;
