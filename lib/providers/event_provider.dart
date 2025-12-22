import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../services/hive_service.dart';

class EventProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  List<EventModel> _events = [];

  DateTime get selectedDate => _selectedDate;
  List<EventModel> get events => _events;

  /// 초기 로드
  Future<void> init([DateTime? date]) async {
    _selectedDate = date ?? DateTime.now();
    loadEventsByDate(_selectedDate);
  }

  /// 날짜 변경
  void changeDate(DateTime date) {
    _selectedDate = date;
    loadEventsByDate(date);
  }

  /// 날짜별 일정 불러오기
  void loadEventsByDate(DateTime date) {
    _events = HiveService.getEventsByDate(date);
    notifyListeners();
  }

  /// 일정 추가
  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required int startHour,
    required int endHour,
  }) async {
    final event = EventModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      date: date,
      startHour: startHour,
      endHour: endHour,
    );

    await HiveService.addEvent(event);
    loadEventsByDate(date);
  }
}
