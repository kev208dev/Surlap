import 'package:flutter/material.dart';

/// 디자인 시스템 토큰 — 전 화면 일관 적용용.
/// 색은 기존 프리셋(context.sh)을 그대로 쓰고, 여기서는 간격·반경·타이포·그림자만 정의.

/// 8pt 그리드 간격(4의 배수).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // 화면 좌우/카드 기본 패딩
  static const double xl = 24; // 섹션 간 간격
  static const double xxl = 32;
}

/// 모서리 반경.
abstract final class Radii {
  static const double card = 16;   // Structured식 부드러움 — 카드/입력
  static const double small = 8;   // 칩·작은 요소
  static const double pill = 999;  // 캡슐형 버튼/배지
  static const double sheet = 20;  // 바텀시트/다이얼로그 등 큰 컨테이너
  static const double hero = 24;   // 큰 카드(계정 카드 등)
}

/// 최소 터치 영역.
const double kMinTouch = 44;

/// Soft shadow 토큰 — 라이트 모드에서 hairline 대신 카드 구분 수단.
/// 다크 모드에서는 시각 효과가 약하므로 hairline 분기 권장(`context.sh.dark`).
abstract final class Shadows {
  /// 가장 미세 — 칩/버튼 hover (3% / blur 8 / y+1)
  static const List<BoxShadow> hairline = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 1)),
  ];

  /// 카드 기본 — 5% / blur 16 / y+4
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// 살짝 들린 카드 — 8% / blur 22 / y+8 (홈 hero 카드 등)
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x14000000), blurRadius: 22, offset: Offset(0, 8)),
  ];

  /// 떠 있는 요소(FAB·바텀바) — 12% / blur 18 / y+6
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
}

/// 타이포 단계. 색상은 호출부에서 copyWith(color:) 로.
abstract final class AppType {
  /// 화면 진입 대제목 28 / bold — "오늘" 등 헤더 전용
  static const TextStyle display =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.4);

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

  /// 카드 위 오버라인(영문 대문자 느낌의 미니 라벨) — 12 / w800 / 트래킹 1.2
  /// 그룹 제목·"DAILY"·"TODAY" 같은 정체성 라벨에.
  static const TextStyle eyebrow = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: 1.2);

  /// 숫자 강조(본문보다 한 단계 크고 굵게)
  static const TextStyle number =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2);
}

/// 모션 토큰 — 시간/곡선 통일. 동일 인터랙션은 동일 timing 으로.
abstract final class Motion {
  /// 즉각적인 micro-feedback(체크/탭) — 120ms
  static const Duration micro = Duration(milliseconds: 120);

  /// UI 상태 전환(세그먼트·필터칩) — 200ms
  static const Duration fast = Duration(milliseconds: 200);

  /// 화면 컴포넌트 등장/사라짐 — 280ms
  static const Duration base = Duration(milliseconds: 280);

  /// 시트·라우트 등 큰 전환 — 380ms
  static const Duration slow = Duration(milliseconds: 380);

  /// 자연스러운 가속·감속 — 일반 UI 전환 기본값.
  static const Curve curve = Curves.easeOutCubic;

  /// 가볍게 튀는 느낌 — 활성 pill/체크 등.
  static const Curve spring = Curves.easeOutBack;

  /// 부드럽고 무거운 감속 — 시트/모달.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// 보더 두께 — 1px 미만은 hairline, 1px+는 divider.
abstract final class Borders {
  static const double hairline = 0.5;
  static const double divider = 1.0;
  static const double thick = 1.5;
}
