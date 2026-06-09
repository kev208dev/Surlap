import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../i18n/app_lang.dart';

/// 앱 언어 상태. 기기 전역(계정 스코프 제외)으로 저장.
class LocaleNotifier extends Notifier<AppLang> {
  @override
  AppLang build() =>
      appLangFromCode(LocalStore.instance.getString(StorageKeys.appLang));

  Future<void> set(AppLang lang) async {
    state = lang;
    await LocalStore.instance.setString(StorageKeys.appLang, lang.code);
  }

  /// 사용자가 한 번이라도 언어를 골랐는지(미선택이면 언어 선택 화면 표시).
  static bool get chosen =>
      LocalStore.instance.getString(StorageKeys.appLang) != null;
}

final localeProvider =
    NotifierProvider<LocaleNotifier, AppLang>(LocaleNotifier.new);
