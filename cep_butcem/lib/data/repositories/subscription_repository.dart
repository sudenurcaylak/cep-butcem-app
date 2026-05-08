import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '/data/models/subscription_model.dart';

class SubscriptionRepository {
  static const String _tableName = 'subscriptions';

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<SubscriptionModel>> getAllSubscriptions() async {
    final db = await _db;

    final result = await db.query(_tableName, orderBy: 'id DESC');

    return result.map((e) => SubscriptionModel.fromMap(e)).toList();
  }

  Future<int> insertSubscription(SubscriptionModel subscription) async {
    final db = await _db;

    return db.insert(
      _tableName,
      subscription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSubscription(SubscriptionModel subscription) async {
    final db = await _db;

    return db.update(
      _tableName,
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final db = await _db;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<SubscriptionModel?> getSubscriptionById(int id) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return SubscriptionModel.fromMap(result.first);
  }
}
