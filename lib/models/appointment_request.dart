class AppointmentRequest {
  DateTime startDate;
  DateTime endDate;
  List<String> members;

  AppointmentRequest({
    required this.startDate,
    required this.endDate,
    required this.members,
  });
}