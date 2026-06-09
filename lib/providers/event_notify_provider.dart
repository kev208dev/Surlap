import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../utils/birthday_notifications.dart' show BirthdayNotifications;
import '../utils/event_notifications.dart';
import 'events_provider.dart';

class EventNotifySettings {
  final bool enabled;
  final int leadMinutes; // 0/5/15/30/60
  const EventNotifySettings({this.enabled = false, this.leadMinutes = 15});

  EventNotifySettings copyWith({bool? enabled, int? leadMinutes}) =>
      EventNotifySettings(
        enabled: enabled ?? this.enabled,
        leadMinutes: leadMinutes ?? this.leadMinutes,
      );
}

class EventNotifyNotifier extends Notifier<EventNotifySettings> {
  @override
  EventNotifySettings build() {
    final s = LocalStore.instance;
    final st = EventNotifySettings(
      enabled: s.getBool(StorageKeys.eventNotifyEnabled) ?? false,
      leadMinutes: s.getInt(StorageKeys.eventNotifyLeadMinutes) ?? 15,
    );
    // 이벤트 변경 시 자동 재스케줄.
    ref.listen<Map<String, dynamic>>(
      _eventsTickProvider,
      (_, _) => reschedule(),
    );
    return st;
  }

  Future<void> setEnabled(bool v) async {
    if (v) {
      await BirthdayNotifications.requestPermission();
    }
    state = state.copyWith(enabled: v);
    await LocalStore.instance.setBool(StorageKeys.eventNotifyEnabled, v);
    await reschedule();
  }

  Future<void> setLeadMinutes(int m) async {
    state = state.copyWith(leadMinutes: m);
    await LocalStore.instance.setInt(StorageKeys.eventNotifyLeadMinutes, m);
    await reschedule();
  }

  Future<void> reschedule() async {
    await EventNotifications.scheduleAll(
      ref.read(eventsProvider),
      enabled: state.enabled,
      leadMinutes: state.leadMinutes,
    );
  }
}

/// events 변경 → notifier가 listen할 수 있도록 dummy map으로 wrap.
final _eventsTickProvider = Provider<Map<String, dynamic>>((ref) {
  final ev = ref.watch(eventsProvider);
  // 정확한 비교가 아닌 ref-equality fingerprint(맵 자체)로 충분.
  return {'_v': ev.length, '_ts': identityHashCode(ev)};
});

final eventNotifyProvider =
    NotifierProvider<EventNotifyNotifier, EventNotifySettings>(
        EventNotifyNotifier.new);
