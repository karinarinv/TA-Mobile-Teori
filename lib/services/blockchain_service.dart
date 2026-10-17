import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'db_helper.dart';
import 'cloud_service.dart';

/// Blockchain sederhana: tiap transaksi menyimpan hash blok sebelumnya.
class BlockchainService {
  static String _calc(Object? data, Object? prev, Object? ts) =>
      sha256.convert(utf8.encode('$data|$prev|$ts')).toString();

  static Future<void> addTransaction(String data) async {
    final db = await DbHelper.db;
    final last = await db.query('ledger', orderBy: 'id DESC', limit: 1);
    final prev = last.isEmpty ? '0' : last.first['hash'] as String;
    final ts = DateTime.now().toIso8601String();
    final row = {'data': data, 'prev_hash': prev, 'hash': _calc(data, prev, ts), 'ts': ts};
    await db.insert('ledger', row);
    await CloudService.insert('ledger', row); // sinkron ke online
  }

  /// Semua blok, terbaru di atas.
  static Future<List<Map<String, Object?>>> all() async =>
      (await DbHelper.db).query('ledger', orderBy: 'id DESC');

  /// Cek rantai (urutan lama ke baru).
  static bool verifyRows(List<Map<String, Object?>> rows) {
    var prev = '0';
    for (final r in rows) {
      if (r['prev_hash'] != prev || r['hash'] != _calc(r['data'], r['prev_hash'], r['ts'])) {
        return false;
      }
      prev = r['hash'] as String;
    }
    return true;
  }

  static Future<bool> verify() async {
    final rows = await (await DbHelper.db).query('ledger', orderBy: 'id ASC');
    return verifyRows(rows);
  }
}