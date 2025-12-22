import 'package:flutter/material.dart';
import '../models/weekly_routine_model.dart';

class WeeklyRoutineProvider extends ChangeNotifier {
  final List<WeeklyRoutine> _routines = [];

  List<WeeklyRoutine> routinesByWeekday(int weekday) {
    return _routines.where((r) => r.weekday == weekday).toList();
  }

  void addRoutine({
    required int weekday,
    required int startHour,
    required int endHour,
  }) {
    _routines.add(
      WeeklyRoutine(
        weekday: weekday,
        startHour: startHour,
        endHour: endHour,
      ),
    );
    notifyListeners();
  }
}
