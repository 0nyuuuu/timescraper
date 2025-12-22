import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/date_event_model.dart';
import '../services/hive_service.dart';

class DateEventProvider extends ChangeNotifier {
  List<DateEventModel> _monthEvents = [];

  List<DateEventModel> get monthEvents => _monthEvents;

  List<DateEventModel> eventsOf(DateTime date) {
    return _monthEvents
        .where((e) =>
    e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  void loadMonth(DateTime month) {
    _monthEvents = HiveService.getDateEventsByMonth(month);
    notifyListeners();
  }

  bool hasEvent(DateTime date) {
    return _monthEvents.any((e) =>
    e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day);
  }

  Future<void> addDateEvent(DateTime date, String title) async {
    final event = DateEventModel(
      id: const Uuid().v4(),
      date: date,
      title: title,
    );

    await HiveService.addDateEvent(event);
    loadMonth(date);
  }

  // ✅ 추가: 수정
  Future<void> updateDateEvent({
    required DateEventModel event,
    required String newTitle,
  }) async {
    final updated = DateEventModel(
      id: event.id,
      date: event.date,
      title: newTitle,
    );

    await HiveService.updateDateEvent(updated);
    loadMonth(event.date);
  }

  // ✅ 추가: 삭제
  Future<void> deleteDateEvent(DateEventModel event) async {
    await HiveService.deleteDateEvent(event.id);
    loadMonth(event.date);
  }
}
