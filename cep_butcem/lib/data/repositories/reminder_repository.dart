import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/reminder_model.dart';

class ReminderRepository {
  static const String _tableName = 'reminders';

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<ReminderModel>> getAllReminders() async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      orderBy: 'remind_at ASC, id DESC',
    );

    return result.map((e) => ReminderModel.fromMap(e)).toList();
  }

  Future<int> insertReminder(ReminderModel reminder) async {
    final db = await _db;

    return db.insert(
      _tableName,
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateReminder(ReminderModel reminder) async {
    final db = await _db;

    return db.update(
      _tableName,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _db;

    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<ReminderModel?> getReminderById(int id) async {
    final db = await _db;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ReminderModel.fromMap(result.first);
  }
}
