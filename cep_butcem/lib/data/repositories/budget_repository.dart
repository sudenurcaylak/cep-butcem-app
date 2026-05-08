import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/budget_setup_data.dart';

class BudgetRepository {
  BudgetRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  static const String _tableName = 'budgets';

  Future<Database> get _db async => _database.database;

  Future<BudgetSetupData?> getBudget() async {
    final db = await _db;

    final result = await db.query(_tableName, orderBy: 'id DESC', limit: 1);

    if (result.isEmpty) return null;

    return BudgetSetupData.fromMap(result.first);
  }

  Future<int> insertBudget(BudgetSetupData budget) async {
    final db = await _db;

    return db.insert(
      _tableName,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateBudget(BudgetSetupData budget) async {
    final db = await _db;

    if (budget.id == null) {
      throw ArgumentError('updateBudget için budget.id null olamaz.');
    }

    return db.update(
      _tableName,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> saveBudget(BudgetSetupData budget) async {
    final existing = await getBudget();

    if (existing == null) {
      await insertBudget(budget);
      return;
    }

    await updateBudget(
      budget.copyWith(id: existing.id, createdAt: existing.createdAt),
    );
  }

  Future<void> deleteAllBudgets() async {
    final db = await _db;
    await db.delete(_tableName);
  }
}
