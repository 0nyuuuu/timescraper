import 'package:hive_flutter/hive_flutter.dart';

import '../models/event_model.dart';
import '../models/appointment.dart';

class HiveService {
  // 시간표 이벤트 (EventModel) - (캘린더 화면에서만 쓰는 기존 이벤트라면 유지)
  static const String eventBoxName = 'events';

  // 캘린더 약속 (Appointment)
  static const String appointmentBoxName = 'appointments';

  // 앱 설정 + 간단 저장소
  static const String appBoxName = 'app_settings';
  static const String firstRunKey = 'first_run';

  // (예전 설정 키들)
  static const String showWeekendKey = 'show_weekend';
  static const String showFullDayKey = 'show_full_day';

  // ✅ 시간표(주간) 저장 키
  static const String weeklyTableKey = 'weekly_table_v1';
  static const String weeklyBlocksKey = 'weekly_blocks_v1';

  // 유저별 닉네임(이제 안 쓰면 나중에 정리 가능)
  static String nicknameKey(String uid) => 'nickname_$uid';

  static late Box<EventModel> eventBox;
  static late Box<Appointment> appointmentBox;
  static late Box appBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // typeId 0: EventModel
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EventModelAdapter());
    }

    // Appointment: typeId 10
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AppointmentAdapter());
    }

    eventBox = await Hive.openBox<EventModel>(eventBoxName);
    appointmentBox = await Hive.openBox<Appointment>(appointmentBoxName);
    appBox = await Hive.openBox(appBoxName);
  }

  // =================
  // First Run (온보딩)
  // =================
  static bool isFirstRun() {
    return appBox.get(firstRunKey, defaultValue: true) as bool;
  }

  static Future<void> setFirstRunFalse() async {
    await appBox.put(firstRunKey, false);
  }

  static Future<void> debugResetFirstRun() async {
    await appBox.put(firstRunKey, true);
  }

  // =========================
  // Settings (시간표 옵션)
  // =========================
  static bool getShowWeekend() =>
      appBox.get(showWeekendKey, defaultValue: false) as bool;

  static bool getShowFullDay() =>
      appBox.get(showFullDayKey, defaultValue: false) as bool;

  static Future<void> setShowWeekend(bool v) async {
    await appBox.put(showWeekendKey, v);
  }

  static Future<void> setShowFullDay(bool v) async {
    await appBox.put(showFullDayKey, v);
  }

  // =========================
  // ✅ Weekly Timetable Persist
  // =========================

  /// weeklyTable 저장 형태:
  /// {
  ///   "1": [0,1,0,...],
  ///   "2": [...],
  /// }
  static Map<String, dynamic> getWeeklyTableRaw() {
    final raw = appBox.get(weeklyTableKey, defaultValue: <String, dynamic>{});
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  static Future<void> setWeeklyTableRaw(Map<String, dynamic> raw) async {
    await appBox.put(weeklyTableKey, raw);
  }

  /// weeklyBlocks 저장 형태: List<Map>
  /// [
  ///  {"id":"..","weekday":1,"startIndex":0,"endIndex":2,"label":"..."},
  /// ]
  static List<Map<String, dynamic>> getWeeklyBlocksRaw() {
    final raw = appBox.get(weeklyBlocksKey, defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> setWeeklyBlocksRaw(List<Map<String, dynamic>> raw) async {
    await appBox.put(weeklyBlocksKey, raw);
  }

  // =========================
  // Nickname (유저별)
  // =========================
  static String getNickname(String uid) =>
      (appBox.get(nicknameKey(uid), defaultValue: '') as String);

  static Future<void> setNickname(String uid, String nickname) async {
    await appBox.put(nicknameKey(uid), nickname);
  }

  // =========================
  // 시간표 이벤트 (EventModel)
  // =========================
  static Future<void> addEvent(EventModel event) async {
    await eventBox.put(event.id, event);
  }

  static List<EventModel> getEventsByDate(DateTime date) {
    return eventBox.values
        .where((e) =>
    e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day)
        .toList();
  }

  // =========================
  // Appointment
  // =========================
  static Future<void> addAppointment(Appointment appt) async {
    await appointmentBox.put(appt.id, appt);
  }

  static Future<void> updateAppointment(Appointment appt) async {
    await appointmentBox.put(appt.id, appt);
  }

  static Future<void> deleteAppointment(String id) async {
    await appointmentBox.delete(id);
  }

  static List<Appointment> getAppointmentsByDate(DateTime date) {
    return appointmentBox.values
        .where((a) =>
    a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day)
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  static List<Appointment> getAppointmentsByMonth(DateTime month) {
    return appointmentBox.values
        .where((a) => a.date.year == month.year && a.date.month == month.month)
        .toList()
      ..sort((a, b) {
        final da = DateTime(a.date.year, a.date.month, a.date.day, a.hour);
        final db = DateTime(b.date.year, b.date.month, b.date.day, b.hour);
        return da.compareTo(db);
      });
  }

  // =========================
  // 추천용: 월별 0/1 배열
  // =========================
  static int _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return last.day;
  }

  static List<int> getBusyArrayByMonth(DateTime month) {
    final m = DateTime(month.year, month.month);
    final days = _daysInMonth(m);
    final result = List<int>.filled(days, 0);

    for (final a in appointmentBox.values) {
      if (a.date.year == m.year && a.date.month == m.month) {
        final d = a.date.day;
        if (d >= 1 && d <= days) result[d - 1] = 1;
      }
    }
    return result;
  }
}
