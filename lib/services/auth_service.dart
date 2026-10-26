import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'cloud_service.dart';

class AuthService {
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

  static Future<bool> updateDisplayName(String username, String displayName) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) return false;

    await (await DbHelper.db).update(
      'users',
      {'display_name': normalizedName},
      where: 'username = ?',
      whereArgs: [username],
    );
    return CloudService.update(
      'users',
      {'display_name': normalizedName},
      filters: {'username': username},
    );
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
