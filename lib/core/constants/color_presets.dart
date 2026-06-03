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

const kDefaultPreset = ColorPreset(
  id: 'light',
  name: 'HourSpace',
  dot: kBrandPurple,
  accent: kBrandPurple,
  accentInk: Color(0xFF4A1FD0),
  accentBg: Color(0xFFEDE8FD),
  app: Color(0xFFF8F7FB),      // 아주 연한 라벤더 배경
  card: Color(0xFFFFFFFF),
  card2: Color(0xFFF6F4FA),    // soft surface
  hairline: Color(0xFFEAE8F0),
  ink: Color(0xFF15151A),      // deep ink
  inkSoft: Color(0xFF6B6B77),
  inkFaint: Color(0xFFA6A6B2),
  dark: false,
);

// presetById 호출 코드 하위 호환용
ColorPreset presetById(String id) => kDefaultPreset;
