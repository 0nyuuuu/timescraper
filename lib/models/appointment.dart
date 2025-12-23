import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 10)
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int hour;

  @HiveField(3)
  String title;

  @HiveField(4)
  List<String> participants;

  Appointment({
    required this.id,
    required this.date,
    required this.hour,
    required this.title,
    required this.participants,
  });
}
