import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/hive_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _monthAppointments = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get month => _month;
  List<Appointment> get monthAppointments => _monthAppointments;

  void loadMonth(DateTime month) {
    _month = DateTime(month.year, month.month);
    _monthAppointments = HiveService.getAppointmentsByMonth(_month);
    notifyListeners();
  }

  List<Appointment> appointmentsOf(DateTime date) {
    return _monthAppointments
        .where((a) =>
    a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day)
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  bool hasAppointment(DateTime date) {
    return _monthAppointments.any((a) =>
    a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day);
  }

  Future<void> add(Appointment appt) async {
    await HiveService.addAppointment(appt);
    loadMonth(appt.date);
  }

  Future<void> update(Appointment appt) async {
    await HiveService.updateAppointment(appt);
    loadMonth(appt.date);
  }

  Future<void> delete(Appointment appt) async {
    await HiveService.deleteAppointment(appt.id);
    loadMonth(appt.date);
  }
}
