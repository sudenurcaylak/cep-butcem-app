import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static const String _tableName = 'transactions';

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _db;

    return db.insert(
      _tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      orderBy: 'transaction_date DESC, id DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      orderBy: 'transaction_date DESC, id DESC',
      limit: limit,
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return TransactionModel.fromMap(result.first);
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _db;

    return db.update(
      _tableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _db;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncome() async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM $_tableName
      WHERE type = ?
    ''',
      ['income'],
    );

    final value = result.first['total'];
    if (value == null) return 0.0;

    return (value as num).toDouble();
  }

  Future<double> getTotalExpense() async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM $_tableName
      WHERE type = ?
    ''',
      ['expense'],
    );

    final value = result.first['total'];
    if (value == null) return 0.0;

    return (value as num).toDouble();
  }

  Future<double> getNetBalance() async {
    final totalIncome = await getTotalIncome();
    final totalExpense = await getTotalExpense();
    return totalIncome - totalExpense;
  }
}
