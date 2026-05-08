import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  static const String _tableName = 'categories';

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _db;

    final result = await db.query(_tableName, orderBy: 'type ASC, name ASC');

    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return CategoryModel.fromMap(result.first);
  }
}
