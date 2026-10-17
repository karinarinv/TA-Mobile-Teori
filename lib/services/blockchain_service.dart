import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'db_helper.dart';
import 'cloud_service.dart';

/// Blockchain sederhana: tiap transaksi menyimpan hash blok sebelumnya.
class BlockchainService {
  static Future<void> addTransaction(String data) async {
    final db = await DbHelper.db;
    final last = await db.query('ledger', orderBy: 'id DESC', limit: 1);
    final prev = last.isEmpty ? '0' : last.first['hash'] as String;
    final ts = DateTime.now().toIso8601String();
    final hash = sha256.convert(utf8.encode('$data|$prev|$ts')).toString();
    final row = {'data': data, 'prev_hash': prev, 'hash': hash, 'ts': ts};
    await db.insert('ledger', row);
    await CloudService.insert('ledger', row); // sinkron ke online
  }

  /// Cek apakah rantai masih valid (tidak dimanipulasi).
  static Future<bool> verify() async {
    final rows = await (await DbHelper.db).query('ledger', orderBy: 'id ASC');
    var prev = '0';
    for (final r in rows) {
      final h = sha256
          .convert(utf8.encode('${r['data']}|${r['prev_hash']}|${r['ts']}'))
          .toString();
      if (r['prev_hash'] != prev || r['hash'] != h) return false;
      prev = r['hash'] as String;
    }
    return true;
  }
}
