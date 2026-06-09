import 'package:flutter/widgets.dart';

/// 지원 언어. 기본 = 한국어.
enum AppLang { ko, en, ja, zh, es }

extension AppLangX on AppLang {
  /// 저장/조회용 코드('ko','en','ja','zh','es').
  String get code => name;

  /// 국기 이모지(언어 선택 화면에 표시).
  String get flag => switch (this) {
        AppLang.ko => '🇰🇷',
        AppLang.en => '🇺🇸',
        AppLang.ja => '🇯🇵',
        AppLang.zh => '🇨🇳',
        AppLang.es => '🇪🇸',
      };

  /// 그 언어로 쓴 언어 이름(자기 언어로 표기).
  String get nativeName => switch (this) {
        AppLang.ko => '한국어',
        AppLang.en => 'English',
        AppLang.ja => '日本語',
        AppLang.zh => '简体中文',
        AppLang.es => 'Español',
      };

  Locale get locale => switch (this) {
        AppLang.ko => const Locale('ko'),
        AppLang.en => const Locale('en'),
        AppLang.ja => const Locale('ja'),
        AppLang.zh => const Locale('zh'),
        AppLang.es => const Locale('es'),
      };
}

/// 코드 → AppLang. 미지정/미지원이면 한국어.
AppLang appLangFromCode(String? code) =>
    AppLang.values.firstWhere((l) => l.name == code, orElse: () => AppLang.ko);
