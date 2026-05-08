import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<SettingsModel> getSettings() async {
    final db = await _db;

    final result = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      final defaults = SettingsModel.defaults();
      await db.insert(
        'settings',
        defaults.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return defaults;
    }

    return SettingsModel.fromMap(result.first);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final db = await _db;

    await db.insert(
      'settings',
      settings.copyWith(id: 1).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateThemeMode(String themeMode) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(themeMode: themeMode));
  }

  Future<void> updateLanguageCode(String languageCode) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(languageCode: languageCode));
  }

  Future<void> updateReminderNotifications(bool enabled) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(reminderNotificationsEnabled: enabled));
  }

  Future<void> updateSubscriptionNotifications(bool enabled) async {
    final current = await getSettings();
    await saveSettings(
      current.copyWith(subscriptionNotificationsEnabled: enabled),
    );
  }
}
