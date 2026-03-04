import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Local SQLite database for caching encrypted vault items (offline support).
///
/// Important: This stores ENCRYPTED blobs — no plaintext passwords at rest.
class LocalDbService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'passman_vault.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vault_items (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            encrypted_blob TEXT NOT NULL,
            nonce TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getVaultItems(String userId) async {
    final db = await database;
    return db.query(
      'vault_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> upsertVaultItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(
      'vault_items',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteVaultItem(String id) async {
    final db = await database;
    await db.delete('vault_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearUserVault(String userId) async {
    final db = await database;
    await db.delete('vault_items', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> replaceAllItems(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'vault_items',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final item in items) {
        await txn.insert('vault_items', item);
      }
    });
  }
}
