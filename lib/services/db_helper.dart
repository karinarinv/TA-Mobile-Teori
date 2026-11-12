import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Membuka SQLite lokal dan memperbarui struktur tabel antarversi aplikasi.
class DbHelper {
  // Database dibuat sekali, lalu instance yang sama dipakai ulang.
  static Database? _db;
  // Getter membuka database hanya saat pertama kali diminta oleh service.
  static Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'rentbook.db'),
    // Naikkan versi saat struktur berubah agar onUpgrade menjalankan migrasi.
    version: 7,
    onCreate: (d, v) async {
      // Akun menyimpan salt/hash password; riwayat menyimpan tautan hash transaksi.
      await d.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, display_name TEXT, username_changed_at TEXT, salt TEXT, hash TEXT, photo TEXT)',
      );
      await d.execute(
        'CREATE TABLE riwayat_transaksi(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, prev_hash TEXT, hash TEXT, ts TEXT, tx_hash TEXT, username TEXT)',
      );
    },
    // Migrasi berurutan menjaga data pengguna lama saat aplikasi diperbarui.
    onUpgrade: (d, oldVersion, newVersion) async {
      // Versi < 3 belum memiliki nama tampilan akun.
      if (oldVersion < 3) {
        await d.execute('ALTER TABLE users ADD COLUMN display_name TEXT');
      }
      // Versi < 4 belum menyimpan tanggal ganti username.
      if (oldVersion < 4) {
        await d.execute(
          'ALTER TABLE users ADD COLUMN username_changed_at TEXT',
        );
      }
      // Versi < 6 memakai nama tabel ledger lama.
      if (oldVersion < 6) {
        await d.execute('ALTER TABLE ledger RENAME TO riwayat_transaksi');
      }
      // Versi 7 membangun ulang tabel users tanpa kolom email lama.
      if (oldVersion < 7) {
        await d.execute('DROP INDEX IF EXISTS users_email_unique');
        await d.execute(
          'CREATE TABLE users_without_email(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, display_name TEXT, username_changed_at TEXT, salt TEXT, hash TEXT, photo TEXT)',
        );
        await d.execute(
          'INSERT INTO users_without_email(id, username, display_name, username_changed_at, salt, hash, photo) SELECT id, username, display_name, username_changed_at, salt, hash, photo FROM users',
        );
        await d.execute('DROP TABLE users');
        await d.execute('ALTER TABLE users_without_email RENAME TO users');
      }
    },
    // Tambah kolom lama secara aman; error berarti kolom itu sudah tersedia.
    onOpen: (d) async {
      try {
        await d.execute(
          'ALTER TABLE riwayat_transaksi ADD COLUMN tx_hash TEXT',
        );
      } catch (_) {}
      try {
        await d.execute(
          'ALTER TABLE riwayat_transaksi ADD COLUMN username TEXT',
        );
      } catch (_) {}
    },
  );
}
