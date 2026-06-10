import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../core/utils/date_utils.dart' as du;
import '../storage/local_store.dart';
import '../utils/birthday_notifications.dart' show BirthdayNotifications;
import '../utils/briefing_notifications.dart';
import 'events_provider.dart';
import 'todos_provider.dart';

class BriefingSettings {
  final bool enabled;
  final int hour; // 0..23
  const BriefingSettings({this.enabled = false, this.hour = 8});

  BriefingSettings copyWith({bool? enabled, int? hour}) =>
      BriefingSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
      );
}

class BriefingNotifier extends Notifier<BriefingSettings> {
  @override
  BriefingSettings build() {
    final s = LocalStore.instance;
    final st = BriefingSettings(
      enabled: s.getBool(StorageKeys.briefingEnabled) ?? false,
      hour: s.getInt(StorageKeys.briefingHour) ?? 8,
    );
    ref.listen<Map<String, dynamic>>(_tickProvider, (_, _) => reschedule());
    return st;
  }

  Future<void> setEnabled(bool v) async {
    if (v) {
      await BirthdayNotifications.requestPermission();
    }
    state = state.copyWith(enabled: v);
    await LocalStore.instance.setBool(StorageKeys.briefingEnabled, v);
    await reschedule();
  }

  Future<void> setHour(int h) async {
    state = state.copyWith(hour: h);
    await LocalStore.instance.setInt(StorageKeys.briefingHour, h);
    await reschedule();
  }

  Future<void> reschedule() async {
    final today = du.toDateKey(DateTime.now());
    final events = ref.read(eventsProvider);
    final todos = ref.read(todosProvider);
    final todayEv = (events[today] ?? const [])
        .where((e) => !e.isTimetable)
        .length;
    final pendingTodos =
        todos.where((t) => !t.done && (t.dateKey == today || t.dateKey == null))
            .length;
    final body = '오늘 일정 $todayEv · 할 일 $pendingTodos';
    await BriefingNotifications.scheduleDaily(
      enabled: state.enabled,
      hour: state.hour,
      body: body,
    );
  }
}

final _tickProvider = Provider<Map<String, dynamic>>((ref) {
  final ev = ref.watch(eventsProvider);
  final td = ref.watch(todosProvider);
  return {'_e': identityHashCode(ev), '_t': identityHashCode(td)};
});

final briefingNotifyProvider =
    NotifierProvider<BriefingNotifier, BriefingSettings>(BriefingNotifier.new);
