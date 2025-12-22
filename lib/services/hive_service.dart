import 'package:hive_flutter/hive_flutter.dart';
import '../models/event_model.dart';
import '../models/date_event_model.dart';

class HiveService {
  static const String eventBoxName = 'events';
  static const String dateEventBoxName = 'date_events';

  static late Box<EventModel> eventBox;
  static late Box<DateEventModel> dateEventBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EventModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DateEventModelAdapter());
    }

    eventBox = await Hive.openBox<EventModel>(eventBoxName);
    dateEventBox = await Hive.openBox<DateEventModel>(dateEventBoxName);
  }

  // 시간표 이벤트
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

  // 날짜 이벤트
  static List<DateEventModel> getDateEventsByMonth(DateTime month) {
    return dateEventBox.values
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
  }

  static Future<void> addDateEvent(DateEventModel event) async {
    await dateEventBox.put(event.id, event);
  }

  // ✅ 추가: 날짜 이벤트 수정
  static Future<void> updateDateEvent(DateEventModel event) async {
    await dateEventBox.put(event.id, event);
  }

  // ✅ 추가: 날짜 이벤트 삭제
  static Future<void> deleteDateEvent(String id) async {
    await dateEventBox.delete(id);
  }
}
