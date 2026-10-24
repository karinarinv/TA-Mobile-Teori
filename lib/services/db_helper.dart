import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> get db async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'rentbook.db'),
        version: 2,
        onCreate: (d, v) async {
          await d.execute(
              'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, salt TEXT, hash TEXT, photo TEXT)');
          await d.execute(
              'CREATE TABLE ledger(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, prev_hash TEXT, hash TEXT, ts TEXT, tx_hash TEXT, username TEXT)');
        },
        onOpen: (d) async {
          try {
            await d.execute('ALTER TABLE ledger ADD COLUMN tx_hash TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE ledger ADD COLUMN username TEXT');
          } catch (_) {}
        },
      );
}
