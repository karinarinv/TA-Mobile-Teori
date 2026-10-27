import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'rentbook.db'),
    version: 7,
    onCreate: (d, v) async {
      await d.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, display_name TEXT, username_changed_at TEXT, salt TEXT, hash TEXT, photo TEXT)',
      );
      await d.execute(
        'CREATE TABLE riwayat_transaksi(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, prev_hash TEXT, hash TEXT, ts TEXT, tx_hash TEXT, username TEXT)',
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
      if (oldVersion < 6) {
        await d.execute('ALTER TABLE ledger RENAME TO riwayat_transaksi');
      }
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
