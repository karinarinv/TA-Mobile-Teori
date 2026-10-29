import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../screens/login_page.dart';
import '../main.dart';

class SessionService {
  static const Duration timeoutDuration = Duration(minutes: 15);
  static const String _keyLastActive = 'session_last_active_ms';

  static int _lastActivityMs = DateTime.now().millisecondsSinceEpoch;
  static Timer? _checkTimer;
  static int _lastPersistedMs = 0;
  static bool _isHandlingTimeout = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastActivityMs = prefs.getInt(_keyLastActive) ?? DateTime.now().millisecondsSinceEpoch;
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkTimeout();
    });
  }

  static void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Catat aktivitas interaksi pengguna (sentuhan, scroll, klik).
  static void recordActivity() {
    _lastActivityMs = DateTime.now().millisecondsSinceEpoch;

    // Simpan ke SharedPreferences secara berkala (tiap 20 detik) agar hemat I/O
    if (_lastActivityMs - _lastPersistedMs > 20000) {
      persistActivity();
    }
  }

  /// Simpan waktu aktivitas terakhir ke SharedPreferences
  static Future<void> persistActivity() async {
    _lastPersistedMs = _lastActivityMs;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastActive, _lastActivityMs);
    } catch (_) {}
  }

  /// Cek apakah sesi yang tersimpan sudah kedaluwarsa (> 15 menit tidak aktif)
  static Future<bool> isSessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('session_user');
      if (user == null || user.trim().isEmpty) {
        return true; // Belum login sama sekali
      }

      final savedMs = prefs.getInt(_keyLastActive);
      if (savedMs == null) {
        // Belum pernah tercatat aktivitas sesi aktif, minta login
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - savedMs;
      // Jika selisih waktu sudah mencapai atau melebihi 15 menit
      return elapsed >= timeoutDuration.inMilliseconds || elapsed < 0;
    } catch (_) {
      return true;
    }
  }

  /// Evaluasi timeout saat aplikasi berjalan atau di-resume dari background
  static Future<void> checkTimeout() async {
    if (_isHandlingTimeout) return;

    final user = await AuthService.currentSession();
    if (user == null || user.trim().isEmpty) {
      // Pengguna belum login, tidak perlu session timeout
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final inMemoryElapsed = now - _lastActivityMs;

    // Baca juga dari storage jika aplikasi baru bangun dari background lama
    final prefs = await SharedPreferences.getInstance();
    final savedMs = prefs.getInt(_keyLastActive) ?? _lastActivityMs;
    final storageElapsed = now - savedMs;

    final elapsed = inMemoryElapsed > storageElapsed ? inMemoryElapsed : storageElapsed;

    if (elapsed >= timeoutDuration.inMilliseconds) {
      _isHandlingTimeout = true;
      try {
        await AuthService.logout();
        await prefs.remove(_keyLastActive);

        final navState = rootNavigatorKey.currentState;
        if (navState != null) {
          navState.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );

          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sesi telah berakhir karena tidak ada aktivitas selama 15 menit. Silakan login kembali.',
                ),
                // WARNA: latar notifikasi.
                backgroundColor: Color(0xFF67343A),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } finally {
        _isHandlingTimeout = false;
        _lastActivityMs = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }
}
