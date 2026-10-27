import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'rentbook.db'),
    version: 6,
    onCreate: (d, v) async {
      await d.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, display_name TEXT, username_changed_at TEXT, email TEXT, salt TEXT, hash TEXT, photo TEXT)',
      );
      await d.execute(
        'CREATE TABLE riwayat_transaksi(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, prev_hash TEXT, hash TEXT, ts TEXT, tx_hash TEXT, username TEXT)',
      );
      await d.execute(
        "CREATE UNIQUE INDEX users_email_unique ON users(LOWER(email)) WHERE email IS NOT NULL AND email != ''",
      );
    },
    onUpgrade: (d, oldVersion, newVersion) async {
      if (oldVersion < 3) {
        await d.execute('ALTER TABLE users ADD COLUMN display_name TEXT');
      }
      if (oldVersion < 4) {
        await d.execute(
          'ALTER TABLE users ADD COLUMN username_changed_at TEXT',
        );
      }
      if (oldVersion < 5) {
        await d.execute('ALTER TABLE users ADD COLUMN email TEXT');
      }
      if (oldVersion < 6) {
        await d.execute('ALTER TABLE ledger RENAME TO riwayat_transaksi');
      }
      await d.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users(LOWER(email)) WHERE email IS NOT NULL AND email != ''",
      );
    },
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
