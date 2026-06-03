import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/color_presets.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

/// 라이트/다크 프리셋 선택 — 기기 설정성 값(계정 동기화 제외)으로 로컬 저장.
class ColorPresetNotifier extends Notifier<ColorPreset> {
  @override
  ColorPreset build() {
    final id = LocalStore.instance.getString(StorageKeys.colorPreset);
    return id == 'dark' ? kDarkPreset : kDefaultPreset;
  }

  bool get isDark => state.dark;

  Future<void> setDark(bool dark) async {
    state = dark ? kDarkPreset : kDefaultPreset;
    await LocalStore.instance
        .setString(StorageKeys.colorPreset, dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setDark(!state.dark);
}

final colorPresetProvider =
    NotifierProvider<ColorPresetNotifier, ColorPreset>(ColorPresetNotifier.new);
