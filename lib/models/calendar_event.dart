import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int hour;

  @HiveField(3)
  String title;

  @HiveField(4)
  String? memo;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.hour,
    required this.title,
    this.memo,
  });
}
