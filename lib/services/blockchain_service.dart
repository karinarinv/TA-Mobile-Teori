// ============================================================================
// FITUR BLOCKCHAIN: LEDGER TRANSAKSI SEWA & INTEGRASI ETHEREUM SEPOLIA
// ----------------------------------------------------------------------------
// Logika Utama:
// 1. Kriptografi SHA-256: Setiap blok memiliki hash yang mengikat data transaksi,
//    prev_hash (hash blok sebelumnya), dan timestamp ISO.
// 2. Genesis Block: Blok pertama memiliki prev_hash = '0'. Blok berikutnya mengikat
//    hash blok sebelumnya membentuk rantai (chain) yang immutable (anti manipulasi).
// 3. Web3 & Smart Contract/Sepolia: Mengirim transaksi payload data ke testnet
//    Ethereum Sepolia via RPC URL, menghasilkan TxHash publik di Etherscan.
// 4. Verifikasi Integritas Rantai: Menelusuri seluruh blok dari awal (id ASC),
//    menghitung ulang SHA-256 tiap blok. Jika ada 1 karakter diubah, verifikasi GAGAL.
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../config.dart';
import 'auth_service.dart';
import 'db_helper.dart';
import 'cloud_service.dart';
import 'notification_service.dart';

/// Membuat rantai hash riwayat sewa lokal dan mencoba menyalinnya ke layanan.
class BlockchainService {
  // =========================================================================
  // LOGIKA 1: FUNGSI HASHING KRIPTOGRAFI (SHA-256)
  // =========================================================================
  // Formula: SHA256(data + "|" + prev_hash + "|" + timestamp)
  // Menghasilkan digest string heksadesimal 64 karakter yang unik.
  // Jika isi data atau urutan blok berubah sedikit saja (Avalanche Effect),
  // hash yang dihasilkan akan berubah total sehingga manipulasi langsung terdeteksi.
  static String _calc(Object? data, Object? prev, Object? ts) =>
      sha256.convert(utf8.encode('$data|$prev|$ts')).toString();

  // =========================================================================
  // LOGIKA 2: BROADCAST TRANSAKSI KE JARINGAN ETHEREUM SEPOLIA (WEB3DART)
  // =========================================================================
  /// Mengirim bukti pencatatan sewa ke jaringan Ethereum Sepolia (Etherscan)
  // 1. Membaca Private Key dari config (sepoliaPrivateKey)
  // 2. Menginisialisasi Web3Client dengan endpoint RPC Sepolia (Alchemy/Infura)
  // 3. Membuat objek Transaction berisikan Uint8List data transaksi sewa
  // 4. Menandatangani dan menyiarkan transaksi ke blockchain Sepolia (Chain ID: 11155111)
  // 5. Mengembalikan txHash unik yang bisa dicek langsung di https://sepolia.etherscan.io
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

  // =========================================================================
  // LOGIKA 3: PEMBUATAN & PENYIMPANAN BLOK BARU (ADD TRANSACTION)
  // =========================================================================
  // 1. Ambil session username pengguna yang aktif
  // 2. Query blok terakhir dari SQLite 'riwayat_transaksi' untuk mengambil 'hash' sebelumnya
  // 3. Jika belum ada blok (Genesis Block), prev_hash diatur ke '0'
  // 4. Catat timestamp realtime saat ini
  // 5. Kirim data ke Ethereum Sepolia (recordToSepolia) untuk mendapatkan TxHash
  // 6. Hitung hash blok baru menggunakan _calc()
  // 7. Simpan blok ke database lokal SQLite dan sinkronisasi ke Supabase Cloud
  static Future<void> addTransaction(String data, [String? user]) async {
    final currentUser = user ?? await AuthService.currentSession() ?? 'anonim';
    final db = await DbHelper.db;
    final last = await db.query(
      'riwayat_transaksi',
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

    await db.insert('riwayat_transaksi', row);
    final sync = await CloudService.insertDetailed('riwayat_transaksi', row);
    if (!sync.success) {
      try {
        await NotificationService.addNotification(
          title: 'Transaksi belum tersinkron',
          message:
              'Transaksi tersimpan di perangkat, tetapi Supabase menolak pengiriman: ${sync.message}',
          type: 'sewa',
        );
      } catch (_) {}
    }
  }

  // =========================================================================
  // LOGIKA 4: MEMBACA SELURUH DAFTAR BLOK DARI DATABASE LOKAL
  // =========================================================================
  // Baca riwayat akun aktif dengan transaksi terbaru lebih dulu (Descending).
  static Future<List<Map<String, Object?>>> all([String? user]) async {
    final currentUser = user ?? await AuthService.currentSession();
    final db = await DbHelper.db;
    if (currentUser != null && currentUser.isNotEmpty) {
      return db.query(
        'riwayat_transaksi',
        where: 'username = ?',
        whereArgs: [currentUser],
        orderBy: 'id DESC',
      );
    }
    return db.query('riwayat_transaksi', orderBy: 'id DESC');
  }

  // =========================================================================
  // LOGIKA 5: VERIFIKASI KEABSAHAN & INTEGRITAS RANTAI BLOK (CHAIN VERIFICATION)
  // =========================================================================
  // Algoritma Verifikasi:
  // 1. Mulai dari Genesis Block dengan prev = '0'.
  // 2. Loop setiap baris:
  //    - Cek apakah prev_hash sama dengan hash blok sebelumnya (r['prev_hash'] == prev).
  //    - Hitung ulang SHA-256 data saat ini menggunakan _calc(data, prev_hash, ts).
  //    - Cek apakah hash yang tercatat di database sama persis dengan hash hasil perhitungan ulang.
  // 3. Jika ada satu saja yang tidak cocok -> Rantai RUSAK / TERMANIPULASI (return false).
  // 4. Jika seluruh blok cocok dari awal hingga akhir -> Rantai VALID (return true).
  static bool verifyRows(List<Map<String, Object?>> rows) {
    var prev = '0';
    for (final r in rows) {
      if (r['prev_hash'] != prev ||
          r['hash'] != _calc(r['data'], r['prev_hash'], r['ts'])) {
        return false;
      }
      prev = r['hash'] as String;
    }
    return true;
  }

  // Ambil data lokal berurutan lama-ke-baru (Ascending) sebelum memeriksa rantainya.
  static Future<bool> verify([String? user]) async {
    final currentUser = user ?? await AuthService.currentSession();
    final db = await DbHelper.db;
    List<Map<String, Object?>> rows;
    if (currentUser != null && currentUser.isNotEmpty) {
      rows = await db.query(
        'riwayat_transaksi',
        where: 'username = ?',
        whereArgs: [currentUser],
        orderBy: 'id ASC',
      );
    } else {
      rows = await db.query('riwayat_transaksi', orderBy: 'id ASC');
    }
    return verifyRows(rows);
  }
}