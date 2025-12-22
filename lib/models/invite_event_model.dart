class InviteEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int startHour;
  final int endHour;

  InviteEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.startHour,
    required this.endHour,
  });
}
