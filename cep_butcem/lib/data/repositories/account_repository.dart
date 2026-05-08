import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/account_model.dart';

class AccountRepository {
  static const String _table = 'accounts';

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<int> insert(AccountModel account) async {
    final db = await _db;

    return db.insert(
      _table,
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AccountModel>> getAll() async {
    final db = await _db;

    final result = await db.query(_table, orderBy: 'id ASC');

    return result.map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<int> update(AccountModel account) async {
    final db = await _db;

    return db.update(
      _table,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> updateBalance({
    required int accountId,
    required double newBalance,
  }) async {
    final db = await _db;

    return db.update(
      _table,
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;

    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalBalance() async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM $_table',
    );

    final value = result.first['total'];

    if (value == null) return 0.0;
    return (value as num).toDouble();
  }
}
