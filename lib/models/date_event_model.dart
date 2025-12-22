import 'package:hive/hive.dart';

part 'date_event_model.g.dart';

@HiveType(typeId: 1)
class DateEventModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  DateEventModel({
    required this.id,
    required this.date,
    required this.title,
  });
}
