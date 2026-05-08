import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cep_butcem.db');

    return openDatabase(
      path,
      version: 8,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        occupation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_balance REAL NOT NULL DEFAULT 0,
        wallet_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER,
        color_value INTEGER,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        icon_code INTEGER,
        color_value INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        account_id INTEGER,
        note TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        billing_day INTEGER NOT NULL,
        provider TEXT NOT NULL DEFAULT 'other',
        period TEXT NOT NULL DEFAULT 'monthly',
        auto_pay INTEGER NOT NULL DEFAULT 0,
        reminders_enabled INTEGER NOT NULL DEFAULT 0,
        remind_days_before INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER,
        account_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        last_processed_month TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        note TEXT,
        remind_at TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        theme_mode TEXT NOT NULL DEFAULT 'dark',
        language_code TEXT NOT NULL DEFAULT 'tr',
        reminder_notifications_enabled INTEGER NOT NULL DEFAULT 1,
        subscription_notifications_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.insert('settings', {
      'id': 1,
      'theme_mode': 'dark',
      'language_code': 'tr',
      'reminder_notifications_enabled': 1,
      'subscription_notifications_enabled': 1,
    });

    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE budgets ADD COLUMN updated_at TEXT
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN provider TEXT NOT NULL DEFAULT 'other'
      ''');

      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN period TEXT NOT NULL DEFAULT 'monthly'
      ''');

      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN auto_pay INTEGER NOT NULL DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN reminders_enabled INTEGER NOT NULL DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN remind_days_before INTEGER NOT NULL DEFAULT 1
      ''');
    }

    if (oldVersion < 4) {
      await _seedCategories(db);
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          balance REAL NOT NULL,
          icon_code INTEGER,
          color_value INTEGER,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY,
          theme_mode TEXT NOT NULL DEFAULT 'dark',
          language_code TEXT NOT NULL DEFAULT 'tr',
          reminder_notifications_enabled INTEGER NOT NULL DEFAULT 1,
          subscription_notifications_enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.insert('settings', {
        'id': 1,
        'theme_mode': 'dark',
        'language_code': 'tr',
        'reminder_notifications_enabled': 1,
        'subscription_notifications_enabled': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN account_id INTEGER
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        ALTER TABLE subscriptions ADD COLUMN account_id INTEGER
      ''');
    }
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {
        'id': 1,
        'name': 'Market',
        'icon_code': Icons.shopping_basket_rounded.codePoint,
        'color_value': const Color(0xFFFF8A00).value,
        'type': 'expense',
      },
      {
        'id': 2,
        'name': 'Giyim',
        'icon_code': Icons.checkroom_rounded.codePoint,
        'color_value': const Color(0xFF20B45B).value,
        'type': 'expense',
      },
      {
        'id': 3,
        'name': 'Kafe',
        'icon_code': Icons.restaurant_rounded.codePoint,
        'color_value': const Color(0xFFFF3B57).value,
        'type': 'expense',
      },
      {
        'id': 4,
        'name': 'Eğitim',
        'icon_code': Icons.menu_book_rounded.codePoint,
        'color_value': const Color(0xFF6C4DFF).value,
        'type': 'expense',
      },
      {
        'id': 5,
        'name': 'Ev',
        'icon_code': Icons.home_rounded.codePoint,
        'color_value': const Color(0xFFFF4DB8).value,
        'type': 'expense',
      },
      {
        'id': 6,
        'name': 'Abonelikler',
        'icon_code': Icons.receipt_long_rounded.codePoint,
        'color_value': const Color(0xFF6C4DFF).value,
        'type': 'expense',
      },
      {
        'id': 7,
        'name': 'Sağlık',
        'icon_code': Icons.local_hospital_rounded.codePoint,
        'color_value': const Color(0xFF20B45B).value,
        'type': 'expense',
      },
      {
        'id': 8,
        'name': 'Spor',
        'icon_code': Icons.fitness_center_rounded.codePoint,
        'color_value': const Color(0xFFFF7A00).value,
        'type': 'expense',
      },
      {
        'id': 9,
        'name': 'Sosyal',
        'icon_code': Icons.groups_rounded.codePoint,
        'color_value': const Color(0xFF00A3FF).value,
        'type': 'expense',
      },
      {
        'id': 10,
        'name': 'Ulaşım',
        'icon_code': Icons.directions_car_rounded.codePoint,
        'color_value': const Color(0xFF2F6BFF).value,
        'type': 'expense',
      },
      {
        'id': 11,
        'name': 'Hediye',
        'icon_code': Icons.card_giftcard_rounded.codePoint,
        'color_value': const Color(0xFF444444).value,
        'type': 'expense',
      },
      {
        'id': 12,
        'name': 'Diğer',
        'icon_code': Icons.question_mark_rounded.codePoint,
        'color_value': const Color(0xFF6C4DFF).value,
        'type': 'expense',
      },
      {
        'id': 101,
        'name': 'Maaş',
        'icon_code': Icons.account_balance_wallet_rounded.codePoint,
        'color_value': const Color(0xFF2F6BFF).value,
        'type': 'income',
      },
      {
        'id': 102,
        'name': 'Hediye',
        'icon_code': Icons.card_giftcard_rounded.codePoint,
        'color_value': const Color(0xFF444444).value,
        'type': 'income',
      },
      {
        'id': 103,
        'name': 'Faiz',
        'icon_code': Icons.savings_rounded.codePoint,
        'color_value': const Color(0xFFFF3B57).value,
        'type': 'income',
      },
      {
        'id': 104,
        'name': 'Diğer',
        'icon_code': Icons.question_mark_rounded.codePoint,
        'color_value': const Color(0xFF6C4DFF).value,
        'type': 'income',
      },
    ];

    final batch = db.batch();

    for (final category in categories) {
      batch.insert(
        'categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }
}
