import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'auth_service.dart';

/// Data satu pemberitahuan; dapat disimpan dan dibaca kembali sebagai JSON.
class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'sewa', 'vip', 'kembali', 'promo'
  final DateTime timestamp;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotificationItem.fromJson(
    Map<String, dynamic> json,
  ) => AppNotificationItem(
    id:
        json['id'] as String? ??
        '${DateTime.now().millisecondsSinceEpoch}_${json['title']?.hashCode}',
    title: json['title'] as String? ?? 'Pemberitahuan',
    message: json['message'] as String? ?? '',
    type: json['type'] as String? ?? 'sewa',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    isRead: json['isRead'] as bool? ?? false,
  );
}

/// Menyiapkan notifikasi Android dan menyimpan riwayat per akun di perangkat.
class NotificationService {
  // ID promo tetap dipakai agar jadwal harian yang sama dapat diganti/dibatalkan.
  static final _n = FlutterLocalNotificationsPlugin();
  static Future<String> _getStorageKey() async {
    final user = await AuthService.currentSession();
    if (user != null && user.trim().isNotEmpty) {
      return 'rentbook_stored_notifications_${user.trim()}';
    }
    return 'rentbook_stored_notifications_guest';
  }

  static const String _promoSettingKey = 'setting_daily_promo_enabled';

  static const _d = NotificationDetails(
    android: AndroidNotificationDetails(
      'rentbook_channel',
      'Pemberitahuan RentBook',
      channelDescription:
          'Notifikasi sewa buku, jatuh tempo, dan promo harian.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // Atur zona waktu WIB, minta izin sistem, lalu pulihkan jadwal promo aktif.
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
    await _n.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _n
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Inisialisasi jadwal harian jika aktif
    if (await isDailyPromoEnabled()) {
      await scheduleDailyPromoNotifications();
    }
  }

  // ============================================================
  // PENGATURAN NOTIFIKASI PROMO HARIAN
  // ============================================================
  static Future<bool> isDailyPromoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promoSettingKey) ?? true;
  }

  static Future<void> setDailyPromoEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promoSettingKey, enabled);
    if (enabled) {
      await scheduleDailyPromoNotifications();
    } else {
      await _n.cancel(8888); // ID khusus promo harian
    }
  }

  // ============================================================
  // PENJADWALAN NOTIFIKASI PROMO HARIAN (PUKUL 09.00)
  // ============================================================
  // Jadwalkan promo pukul 09.00 WIB setiap hari; fallback memakai jadwal tak presisi.
  static Future<void> scheduleDailyPromoNotifications() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // Pukul 09.00 pagi WIB
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _n.zonedSchedule(
        8888,
        'Promo Sewa Pilihan Hari Ini',
        'Gunakan voucher DISKON10 untuk potongan sewa 10 persen bagi seluruh koleksi sastra dan fiksi.',
        scheduledDate,
        _d,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      try {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          9,
          0,
        );
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        await _n.zonedSchedule(
          8888,
          'Promo Sewa Pilihan Hari Ini',
          'Gunakan voucher DISKON10 untuk potongan sewa 10 persen bagi seluruh koleksi sastra dan fiksi.',
          scheduledDate,
          _d,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  // ============================================================
  // PENYIMPANAN RIWAYAT NOTIFIKASI (STORAGE)
  // ============================================================
  static Future<List<AppNotificationItem>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => AppNotificationItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    final list = await getNotifications();
    return list.where((n) => !n.isRead).length;
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final list = await getNotifications();
    list.insert(
      0,
      AppNotificationItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
    // Simpan maksimal 60 notifikasi
    if (list.length > 60) {
      list.removeRange(60, list.length);
    }
    await _saveList(list);
  }

  static Future<void> markAsRead(String id) async {
    final list = await getNotifications();
    for (final item in list) {
      if (item.id == id) {
        item.isRead = true;
        break;
      }
    }
    await _saveList(list);
  }

  static Future<void> markAllAsRead() async {
    final list = await getNotifications();
    for (final item in list) {
      item.isRead = true;
    }
    await _saveList(list);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    await prefs.remove(key);
  }

  static Future<void> _saveList(List<AppNotificationItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonStr);
  }

  // ============================================================
  // PEMICU NOTIFIKASI SISTEM (AKTIVITAS SEWA, VIP, & JATUH TEMPO)
  // ============================================================

  /// Notifikasi pembayaran sewa berhasil
  static Future<void> showPaymentSuccess(
    String title,
    String amount,
    String method,
  ) async {
    final notifTitle = 'Pembayaran Berhasil ($method)';
    final notifBody = '$title sebesar $amount telah dikonfirmasi via $method.';

    try {
      await _n.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notifTitle,
        notifBody,
        _d,
      );
    } catch (_) {}

    await addNotification(title: notifTitle, message: notifBody, type: 'sewa');
  }

  /// Notifikasi aktivasi VIP berhasil
  static Future<void> showVipSuccess(String method) async {
    const notifTitle = 'Keanggotaan VIP Aktif';
    final notifBody =
        'Langganan RentBook VIP via $method telah aktif. Nikmati akses eksklusif seluruh fitur.';

    try {
      await _n.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notifTitle,
        notifBody,
        _d,
      );
    } catch (_) {}

    await addNotification(title: notifTitle, message: notifBody, type: 'vip');
  }

  /// Notifikasi peminjaman & jadwal pengingat jatuh tempo
  // Tampilkan konfirmasi sewa sekarang dan pengingat menjelang batas pengembalian.
  static Future<void> scheduleReturn(String title, {int days = 3}) async {
    final notifTitle = 'Peminjaman Berhasil';
    final notifBody = '"$title" berhasil disewa untuk $days hari ke depan.';

    try {
      await _n.show(1, notifTitle, notifBody, _d);

      // Jadwal reminder jatuh tempo
      await _n.zonedSchedule(
        title.hashCode,
        'Pengingat Batas Pengembalian',
        'Masa sewa untuk "$title" ($days hari) segera berakhir. Silakan kembalikan tepat waktu.',
        tz.TZDateTime.now(tz.local)
            .add(Duration(days: days > 1 ? days - 1 : 1)),
        _d,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}

    await addNotification(title: notifTitle, message: notifBody, type: 'sewa');
  }
}
