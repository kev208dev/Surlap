import 'app_lang.dart';
import 'translations.dart';

/// 현재 언어. app.dart에서 localeProvider를 watch 해 매 빌드마다 동기화한다.
/// 언어가 바뀌면 MaterialApp.locale도 바뀌어 트리 전체가 리빌드되므로,
/// 모든 [tr] 호출이 새 언어로 재평가된다.
AppLang currentLang = AppLang.ko;

/// 한국어 원문을 키로 현재 언어 번역을 돌려준다.
/// 번역이 없으면 한국어 원문을 그대로 반환(부분 번역에도 앱이 깨지지 않음).
String tr(String ko) {
  if (currentLang == AppLang.ko) return ko;
  return kTranslations[ko]?[currentLang] ?? ko;
}

/// 치환형 — {0},{1}... 자리표시자를 args로 채운다.
String trf(String ko, List<Object> args) {
  var s = tr(ko);
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}
