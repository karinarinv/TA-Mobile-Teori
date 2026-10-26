import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'cloud_service.dart';

class UsernameChangeResult {
  final bool success;
  final String message;
  final DateTime? availableAt;
  final bool cloudSynced;
  final String cloudSyncDetails;

  const UsernameChangeResult({
    required this.success,
    required this.message,
    this.availableAt,
    this.cloudSynced = false,
    this.cloudSyncDetails = '',
  });
}

class AuthService {
  static const usernameChangeCooldown = Duration(days: 30);

static String _hash(String pass, String salt) {
  List<int> h = utf8.encode(salt + pass);
  for (var i = 0; i < 1000; i++) {
    h = sha256.convert(h).bytes; // key stretching
  }
  return base64Encode(h);
}

  static String _newSalt() {
    final r = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static Future<bool> register(String user, String pass) async {
    final db = await DbHelper.db;
    final salt = _newSalt();
    try {
      final row = {
        'username': user,
        'display_name': user,
        'salt': salt,
        'hash': _hash(pass, salt),
      };
      await db.insert('users', row);
      await CloudService.insert('users', row); // sinkron ke online
      return true;
    } catch (_) {
      return false; // username sudah dipakai
    }
  }

  static Future<bool> login(String user, String pass) async {
    final db = await DbHelper.db;
    final rows = await db.query('users', where: 'username=?', whereArgs: [user]);
    if (rows.isEmpty) return false;
    final ok = _hash(pass, rows.first['salt'] as String) == rows.first['hash'];
    if (ok) await _setSession(user);
    return ok;
  }

  static Future<void> _setSession(String user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('session_user', user);
    await p.setString('last_user', user); // untuk login biometrik
  }

  static Future<String?> currentSession() async =>
      (await SharedPreferences.getInstance()).getString('session_user');

  static Future<UsernameChangeResult> changeUsername(String requestedUsername) async {
    final newUsername = requestedUsername.trim();
    final oldUsername = await currentSession();
    if (oldUsername == null || oldUsername.isEmpty) {
      return const UsernameChangeResult(
        success: false,
        message: 'Sesi akun tidak ditemukan. Silakan login kembali.',
      );
    }
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(newUsername)) {
      return const UsernameChangeResult(
        success: false,
        message: 'Username harus 3-20 karakter dan hanya berisi huruf, angka, atau underscore.',
      );
    }
    if (newUsername.toLowerCase() == oldUsername.toLowerCase()) {
      return const UsernameChangeResult(
        success: false,
        message: 'Username baru sama dengan username saat ini.',
      );
    }

    final db = await DbHelper.db;
    final currentRows = await db.query(
      'users',
      columns: ['display_name', 'username_changed_at'],
      where: 'username = ?',
      whereArgs: [oldUsername],
      limit: 1,
    );
    if (currentRows.isEmpty) {
      return const UsernameChangeResult(
        success: false,
        message: 'Data akun tidak ditemukan.',
      );
    }

    final lastChangedAt = DateTime.tryParse(
      currentRows.first['username_changed_at'] as String? ?? '',
    );
    final availableAt = lastChangedAt?.add(usernameChangeCooldown);
    final now = DateTime.now();
    if (availableAt != null && now.isBefore(availableAt)) {
      return UsernameChangeResult(
        success: false,
        message: 'Username hanya bisa diganti sekali setiap 30 hari.',
        availableAt: availableAt,
      );
    }

    final duplicate = await db.query(
      'users',
      columns: ['id'],
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [newUsername],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      return const UsernameChangeResult(
        success: false,
        message: 'Username sudah digunakan akun lain.',
      );
    }

    final displayName = currentRows.first['display_name'] as String?;
    final values = <String, dynamic>{
      'username': newUsername,
      'username_changed_at': now.toIso8601String(),
      if (displayName == null || displayName.trim() == oldUsername)
        'display_name': newUsername,
    };
    try {
      await db.transaction((txn) async {
        await txn.update(
          'users',
          values,
          where: 'username = ?',
          whereArgs: [oldUsername],
        );
        await txn.update(
          'ledger',
          {'username': newUsername},
          where: 'username = ?',
          whereArgs: [oldUsername],
        );
      });
    } catch (_) {
      return const UsernameChangeResult(
        success: false,
        message: 'Username gagal diperbarui. Coba gunakan username lain.',
      );
    }

    await _moveUserPreferences(oldUsername, newUsername);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_user', newUsername);
    await prefs.setString('last_user', newUsername);

    final cloudResults = await Future.wait([
      CloudService.update(
        'users',
        values,
        filters: {'username': oldUsername},
      ),
      CloudService.update(
        'ledger',
        {'username': newUsername},
        filters: {'username': oldUsername},
      ),
    ]);
    final usersSync = cloudResults[0];
    final ledgerSync = cloudResults[1];
    final cloudSynced = usersSync.success && ledgerSync.success;
    final cloudSyncDetails = [
      if (!usersSync.success) 'users: ${usersSync.message}',
      if (!ledgerSync.success) 'ledger: ${ledgerSync.message}',
    ].join('\n');
    return UsernameChangeResult(
      success: true,
      cloudSynced: cloudSynced,
      message: cloudSynced
          ? 'Username berhasil diganti.'
          : 'Username berubah di perangkat, tetapi sinkronisasi Supabase gagal.',
      cloudSyncDetails: cloudSyncDetails,
    );
  }

  static Future<void> _moveUserPreferences(
    String oldUsername,
    String newUsername,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userKeys = [
      'vip_user_$oldUsername',
      'vip_expiry_user_$oldUsername',
      'voucher_diskon10_used_$oldUsername',
      'last_rented_genre_$oldUsername',
      'bookmarks_$oldUsername',
      'feedback_kesan_$oldUsername',
      'feedback_saran_$oldUsername',
      'feedback_rating_$oldUsername',
      'feedback_date_$oldUsername',
    ];

    for (final oldKey in userKeys) {
      final value = prefs.get(oldKey);
      if (value == null) continue;
      final prefix = oldKey.substring(0, oldKey.length - oldUsername.length);
      final newKey = '$prefix$newUsername';
      final existing = prefs.get(newKey);

      if (value is bool) {
        await prefs.setBool(newKey, value || (existing is bool && existing));
      } else if (value is int && existing == null) {
        await prefs.setInt(newKey, value);
      } else if (value is double && existing == null) {
        await prefs.setDouble(newKey, value);
      } else if (value is String && existing == null) {
        await prefs.setString(newKey, value);
      } else if (value is List<String>) {
        final merged = <String>{
          if (existing is List<String>) ...existing,
          ...value,
        };
        await prefs.setStringList(newKey, merged.toList());
      }
      await prefs.remove(oldKey);
    }
  }

  static Future<void> logout() async =>
      (await SharedPreferences.getInstance()).remove('session_user');

  static Future<bool> loginBiometric() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString('last_user');
    if (last == null) return false;
    final auth = LocalAuthentication();
    if (!await auth.isDeviceSupported()) return false;
    final ok = await auth.authenticate(localizedReason: 'Masuk ke RentBook');
    if (ok) await _setSession(last);
    return ok;
  }
}
