// 스포츠 데이터 소스 API 설정.
// 키는 빌드 시 --dart-define-from-file=.dart_define 로 주입(env 관리).
//   flutter run --dart-define-from-file=.dart_define

// ── BallDontLie (🏀 NBA) ──
// defaultValue 로 키를 코드에 내장 → 빌드 시 --dart-define 없어도 항상 동작.
// (--dart-define 으로 넘기면 그 값이 우선 적용됨.)
const String ballDontLieApiKey = String.fromEnvironment(
  'BALLDONTLIE_API_KEY',
  defaultValue: 'e80ec442-83a1-4e6b-953b-d6976594a4c7',
);
const String ballDontLieHost = 'https://api.balldontlie.io';
bool get hasSportsApiKey => ballDontLieApiKey.isNotEmpty;

// ── football-data.org (⚽ 축구: EPL 등) ──
const String footballDataApiKey = String.fromEnvironment(
  'FOOTBALL_DATA_API_KEY',
  defaultValue: '3c0c1a314bc846088b3ccff34596c75c',
);
const String footballDataHost = 'https://api.football-data.org/v4';
bool get hasFootballDataKey => footballDataApiKey.isNotEmpty;

// ── PandaScore (🎮 e스포츠: LoL) ──
const String pandascoreApiKey = String.fromEnvironment(
  'PANDASCORE_API_KEY',
  defaultValue: 'pVqHzU976zvfBCulSDdW5Rk7Pn6L3T5PsnSFSYBmPrJ6fUHZHAI',
);
const String pandascoreHost = 'https://api.pandascore.co';
bool get hasPandascoreKey => pandascoreApiKey.isNotEmpty;

// ── Jolpica (🏎️ F1) — 무인증, 키 불필요 ──
const String jolpicaHost = 'https://api.jolpi.ca/ergast/f1';
