import 'package:hive/hive.dart';

part 'time_table.g.dart';

@HiveType(typeId: 1)
class TimeTable extends HiveObject {
  @HiveField(0)
  int weekday; // 1~7 (월~일)

  @HiveField(1)
  int startHour;

  @HiveField(2)
  int endHour;

  @HiveField(3)
  String label;

  TimeTable({
    required this.weekday,
    required this.startHour,
    required this.endHour,
    required this.label,
  });
}
