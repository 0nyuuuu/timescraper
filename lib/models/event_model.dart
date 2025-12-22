import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 0)
class EventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final int startHour;

  @HiveField(5)
  final int endHour;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startHour,
    required this.endHour,
  });
}
