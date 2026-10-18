import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _n = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _n.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _n
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _d = NotificationDetails(
      android: AndroidNotificationDetails('rentbook', 'Pengingat Buku',
          importance: Importance.high, priority: Priority.high));

  /// Notifikasi langsung + pengingat jatuh tempo (demo: 1 menit; durasi hari: days).
  static Future<void> scheduleReturn(String title, {int days = 3}) async {
    await _n.show(
      1,
      'Peminjaman Berhasil',
      '"$title" berhasil disewa untuk $days hari ke depan.',
      _d,
    );
    await _n.zonedSchedule(
      title.hashCode,
      'Pengingat Jatuh Tempo!',
      'Masa sewa "$title" ($days hari) hampir habis. Segera kembalikan tepat waktu.',
      tz.TZDateTime.now(tz.UTC).add(const Duration(minutes: 1)),
      _d,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
