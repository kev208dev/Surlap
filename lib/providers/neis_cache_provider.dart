import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../core/utils/date_utils.dart' as du;
import '../storage/local_store.dart';
import '../supabase/neis_service.dart';

/// NEIS 시간표/급식 — 이번 주(월요일 기준) 캐시.
/// di: 0=월..6=일, period→과목 / di→급식.
class NeisData {
  final Map<int, Map<int, String>> timetable;
  final Map<int, String> lunch;
  const NeisData({this.timetable = const {}, this.lunch = const {}});

  bool get isEmpty => timetable.isEmpty;
}

/// keep-alive provider — 한 번 로드하면 뷰 재진입 시 즉시 사용(재요청 없음).
class NeisCacheNotifier extends Notifier<NeisData> {
  bool _fetching = false;

  @override
  NeisData build() {
    final loaded = _loadLocal();
    // 이번 주 캐시가 없고 학교가 연결돼 있으면 1회만 네트워크 요청.
    if (loaded.isEmpty && NeisSchool.load() != null) {
      Future.microtask(_fetchIfNeeded);
    }
    return loaded;
  }

  String _weekKey() => du.toDateKey(_weekDays().first);

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
        7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  NeisData _loadLocal() {
    final raw = LocalStore.instance.getString(StorageKeys.neisCache);
    if (raw == null) return const NeisData();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['week'] != _weekKey()) return const NeisData(); // 다른 주 → 무시
      final data = <int, Map<int, String>>{};
      (j['data'] as Map<String, dynamic>? ?? {}).forEach((di, pm) {
        final m = <int, String>{};
        (pm as Map<String, dynamic>).forEach((p, s) {
          m[int.parse(p)] = s.toString();
        });
        data[int.parse(di)] = m;
      });
      final lunch = <int, String>{};
      (j['lunch'] as Map<String, dynamic>? ?? {})
          .forEach((di, s) => lunch[int.parse(di)] = s.toString());
      return NeisData(timetable: data, lunch: lunch);
    } catch (_) {
      return const NeisData();
    }
  }

  void _saveLocal(NeisData d) {
    final j = {
      'week': _weekKey(),
      'data': d.timetable
          .map((di, pm) => MapEntry('$di', pm.map((p, s) => MapEntry('$p', s)))),
      'lunch': d.lunch.map((di, s) => MapEntry('$di', s)),
    };
    LocalStore.instance.setString(StorageKeys.neisCache, jsonEncode(j));
  }

  Future<void> _fetchIfNeeded() async {
    if (_fetching) return;
    final school = NeisSchool.load();
    if (school == null) return;
    if (state.timetable.isNotEmpty) return;
    _fetching = true;
    final days = _weekDays();
    final tt = <int, Map<int, String>>{};
    final lunch = <int, String>{};
    for (int di = 0; di < 5; di++) {
      final dateStr = du.toDateKey(days[di]).replaceAll('-', '');
      try {
        final t = await fetchTimetable(school, dateStr);
        if (t != null) tt[di] = t;
        final l = await fetchLunch(school, dateStr);
        if (l != null) lunch[di] = l;
      } catch (e) {
        debugPrint('[NEIS] $dateStr error: $e');
      }
    }
    _fetching = false;
    if (tt.isNotEmpty || lunch.isNotEmpty) {
      final next = NeisData(timetable: tt, lunch: lunch);
      state = next;
      _saveLocal(next);
    }
  }

  /// 학교 재연결 등으로 강제 새로고침.
  Future<void> refresh() async {
    state = const NeisData();
    await _fetchIfNeeded();
  }
}

final neisCacheProvider =
    NotifierProvider<NeisCacheNotifier, NeisData>(NeisCacheNotifier.new);
