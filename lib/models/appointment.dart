import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 10) // ✅ 충돌 방지: Appointment는 10 고정
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date; // 날짜(시간은 hour에)

  @HiveField(2)
  int hour;

  @HiveField(3)
  String title;

  @HiveField(4)
  List<String> participants;

  // ✅ 추가
  @HiveField(5)
  String creatorId;

  Appointment({
    required this.id,
    required this.date,
    required this.hour,
    required this.title,
    required this.participants,
    required this.creatorId,
  });
}
