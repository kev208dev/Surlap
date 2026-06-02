import 'package:flutter/material.dart';

/// 디자인 시스템 토큰 — 전 화면 일관 적용용.
/// 색은 기존 프리셋(context.sh)을 그대로 쓰고, 여기서는 간격·반경·타이포만 정의.

/// 8pt 그리드 간격(4의 배수).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // 화면 좌우/카드 기본 패딩
  static const double xl = 24; // 섹션 간 간격
  static const double xxl = 32;
}

/// 모서리 반경(2종).
abstract final class Radii {
  static const double card = 12;
  static const double small = 8;
}

/// 최소 터치 영역.
const double kMinTouch = 44;

/// 타이포 5단계 (line-height ≈ 1.4). 색상은 호출부에서 copyWith(color:) 로.
abstract final class AppType {
  /// 화면 제목 20 / semibold
  static const TextStyle title =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35);

  /// 섹션 헤더 16 / semibold
  static const TextStyle section =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  /// 본문 14 / regular
  static const TextStyle body =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  /// 보조·캡션 12 / regular (흐린 색 권장)
  static const TextStyle caption =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  /// 작은 라벨/오버라인 11 / medium
  static const TextStyle label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.3);

  /// 숫자 강조(본문보다 한 단계 크고 굵게)
  static const TextStyle number =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2);
}
