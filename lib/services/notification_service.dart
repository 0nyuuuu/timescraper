import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;

    // timezone init
    tz.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(initSettings);
    _inited = true;
  }

  /// appointment 1시간 전 알림
  Future<void> scheduleOneHourBefore({
    required int notificationId,
    required DateTime appointmentDateTime,
    required String title,
  }) async {
    if (!_inited) return;

    final notifyAt = appointmentDateTime.subtract(const Duration(hours: 1));
    if (notifyAt.isBefore(DateTime.now())) {
      // 이미 지난 시간이면 예약하지 않음
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'appointments',
        'Appointments',
        channelDescription: '약속 알림',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      notificationId,
      '약속 1시간 전',
      title,
      tz.TZDateTime.from(notifyAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }
}
