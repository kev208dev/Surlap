import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 래퍼 — 웹 localStorage와 동일한 get/set 인터페이스.
///
/// 주의: 클라우드(user_data)·백업에서 받은 값은 웹 localStorage 형식이라
/// 모두 문자열("true"/"false"/"5")로 저장된다. 그래서 타입 게터는 실제 저장
/// 타입에 관계없이 관대하게 변환한다(문자열로 저장된 bool/int도 안전하게 읽음).
/// 이렇게 하지 않으면 _prefs.getBool 이 String 값에 대해
/// "type 'String' is not a subtype of type 'bool?'" 로 크래시한다.
class LocalStore {
  LocalStore._();
  static LocalStore? _instance;
  static LocalStore get instance => _instance!;

  late SharedPreferences _prefs;

  static Future<LocalStore> init() async {
    _instance ??= LocalStore._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  String? getString(String key) {
    final v = _prefs.get(key);
    return v?.toString();
  }

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  bool? getBool(String key) {
    final v = _prefs.get(key);
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0' || s.isEmpty) return false;
    }
    return null;
  }

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) {
    final v = _prefs.get(key);
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}
