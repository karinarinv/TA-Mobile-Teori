import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../config.dart';
import 'auth_service.dart';
import 'db_helper.dart';
import 'cloud_service.dart';

class BlockchainService {
  static String _calc(Object? data, Object? prev, Object? ts) =>
      sha256.convert(utf8.encode('$data|$prev|$ts')).toString();

  /// Mengirim bukti pencatatan sewa ke jaringan Ethereum Sepolia (Etherscan)
  static Future<String?> recordToSepolia(String data) async {
    final pk = sepoliaPrivateKey.trim();
    if (pk.isEmpty) {
      return null;
    }

    try {
      final cleanPk = pk.startsWith('0x') ? pk.substring(2) : pk;
      final httpClient = http.Client();
      final ethClient = Web3Client(sepoliaRpcUrl, httpClient);
      final credentials = EthPrivateKey.fromHex(cleanPk);

      final txHash = await ethClient
          .sendTransaction(
            credentials,
            Transaction(
              to: credentials.address,
              value: EtherAmount.zero(),
              data: Uint8List.fromList(utf8.encode(data)),
            ),
            chainId: sepoliaChainId,
          )
          .timeout(const Duration(seconds: 15));

      return txHash;
    } catch (_) {
      // Jika offline atau saldo habis, transaksi sewa lokal tetap berjalan aman
      return null;
    }
  }

  static Future<void> addTransaction(String data, [String? user]) async {
    final currentUser = user ?? await AuthService.currentSession() ?? 'anonim';
    final db = await DbHelper.db;
    final last = await db.query(
      'ledger',
      where: 'username = ?',
      whereArgs: [currentUser],
      orderBy: 'id DESC',
      limit: 1,
    );
    final prev = last.isEmpty ? '0' : last.first['hash'] as String;
    final ts = DateTime.now().toIso8601String();

    // Catat ke Ethereum Sepolia jika Private Key sudah dimasukkan
    final txHash = await recordToSepolia(data);

    final row = {
      'data': data,
      'prev_hash': prev,
      'hash': _calc(data, prev, ts),
      'ts': ts,
      'tx_hash': txHash,
      'username': currentUser,
    };

    await db.insert('ledger', row);
    try {
      await CloudService.insert('ledger', row); // sinkron ke online
    } catch (_) {}
  }

  static Future<List<Map<String, Object?>>> all([String? user]) async {
    final currentUser = user ?? await AuthService.currentSession();
    final db = await DbHelper.db;
    if (currentUser != null && currentUser.isNotEmpty) {
      return db.query(
        'ledger',
        where: 'username = ?',
        whereArgs: [currentUser],
        orderBy: 'id DESC',
      );
    }
    return db.query('ledger', orderBy: 'id DESC');
  }

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

  static Future<bool> verify([String? user]) async {
    final currentUser = user ?? await AuthService.currentSession();
    final db = await DbHelper.db;
    List<Map<String, Object?>> rows;
    if (currentUser != null && currentUser.isNotEmpty) {
      rows = await db.query(
        'ledger',
        where: 'username = ?',
        whereArgs: [currentUser],
        orderBy: 'id ASC',
      );
    } else {
      rows = await db.query('ledger', orderBy: 'id ASC');
    }
    return verifyRows(rows);
  }
}
