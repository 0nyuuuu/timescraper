import 'package:hive_flutter/hive_flutter.dart';

import '../models/event_model.dart';
import '../models/appointment.dart';

class HiveService {
  // 시간표 이벤트 (EventModel) - 시간표에서만 사용
  static const String eventBoxName = 'events';

  // 캘린더 약속 (Appointment) - 캘린더 표시의 정답
  static const String appointmentBoxName = 'appointments';

  // 앱 설정
  static const String appBoxName = 'app_settings';
  static const String firstRunKey = 'first_run';

  static late Box<EventModel> eventBox;
  static late Box<Appointment> appointmentBox;

  // 설정용 박스(타입 없음)
  static late Box appBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // typeId 0: EventModel (기존)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EventModelAdapter());
    }

    // typeId 2: Appointment
    if (!Hive.isAdapterRegistered(2)) {
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
  // ✅ 약속(Appointment) - 캘린더 표시
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
  // 추천용: 월별 0/1 배열 (Appointment 기준)
  // =========================
  static int _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return last.day;
  }

  /// 1 = 그 날에 약속(Appointment)이 있음
  /// 0 = 없음
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
