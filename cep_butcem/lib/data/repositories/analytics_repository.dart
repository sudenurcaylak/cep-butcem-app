import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/analytics_data.dart';
import '../models/analytics_params.dart';

class AnalyticsRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<AnalyticsData> getAnalytics(AnalyticsParams params) async {
    final db = await _db;

    final range = _resolveRange(params);
    final prevRange = _resolvePreviousRange(params);

    final currentTotal = await _getTotal(
      db,
      range,
      params.mode,
      params.category,
    );

    final prevTotal = await _getTotal(
      db,
      prevRange,
      params.mode,
      params.category,
    );

    final breakdown = await _getCategoryBreakdown(
      db,
      range,
      params.mode,
      params.category,
    );

    final donut = breakdown.take(3).map((e) {
      return AnalyticsDonutSegment(e.name, e.pct, e.color);
    }).toList();

    while (donut.length < 3) {
      donut.add(const AnalyticsDonutSegment('—', 0.0, Color(0xFFEAEAF3)));
    }

    final trend = await _getTrend(
      db,
      range,
      params.mode,
      params.range,
      params.category,
    );

    final average = _calculateAverage(
      total: currentTotal,
      range: params.range,
      anchor: params.anchor,
    );

    final insight = _buildInsight(
      currentTotal,
      prevTotal,
      breakdown,
      params.mode,
    );

    final suggestion = _buildSuggestion(currentTotal, prevTotal, params.mode);

    return AnalyticsData(
      total: currentTotal,
      average: average,
      trendPointsNormalized: trend,
      donutSegments: donut,
      breakdownAll: breakdown,
      currentTotal: currentTotal,
      prevTotal: prevTotal,
      insightText: insight.$1,
      insightSubText: insight.$2,
      suggestionText: suggestion.$1,
      suggestionSubText: suggestion.$2,
    );
  }

  Future<double> _getTotal(
    Database db,
    _DateRange range,
    String type,
    String category,
  ) async {
    final whereCategory = category == 'Tümü' ? '' : 'AND c.name = ?';
    final args = <Object?>[
      type,
      range.start.toIso8601String(),
      range.end.toIso8601String(),
      if (category != 'Tümü') category,
    ];

    final result = await db.rawQuery('''
      SELECT SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ?
        AND t.transaction_date >= ?
        AND t.transaction_date < ?
        $whereCategory
      ''', args);

    final value = result.first['total'];
    return value == null ? 0.0 : (value as num).toDouble();
  }

  Future<List<AnalyticsBreakdownItem>> _getCategoryBreakdown(
    Database db,
    _DateRange range,
    String type,
    String category,
  ) async {
    final whereCategory = category == 'Tümü' ? '' : 'AND c.name = ?';
    final args = <Object?>[
      type,
      range.start.toIso8601String(),
      range.end.toIso8601String(),
      if (category != 'Tümü') category,
    ];

    final result = await db.rawQuery('''
      SELECT
        c.id,
        c.name,
        c.color_value,
        SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ?
        AND t.transaction_date >= ?
        AND t.transaction_date < ?
        $whereCategory
      GROUP BY c.id, c.name, c.color_value
      ORDER BY total DESC
      ''', args);

    final total = result.fold<double>(
      0.0,
      (sum, e) => sum + ((e['total'] as num?)?.toDouble() ?? 0.0),
    );

    if (total == 0) return [];

    return result.map((e) {
      final amount = (e['total'] as num).toDouble();
      final colorValue = (e['color_value'] as num?)?.toInt() ?? 0xFF8E8E93;

      return AnalyticsBreakdownItem(
        name: e['name'] as String? ?? 'Diğer',
        amount: amount,
        pct: amount / total,
        color: Color(colorValue),
      );
    }).toList();
  }

  Future<List<double>> _getTrend(
    Database db,
    _DateRange range,
    String type,
    String rangeType,
    String category,
  ) async {
    final txs = await _getTransactionsForRange(db, range, type, category);

    switch (rangeType) {
      case 'day':
        return _buildDayTrend(range.start, txs);
      case 'week':
        return _buildWeekTrend(range.start, txs);
      case 'month':
        return _buildMonthTrend(range.start, range.end, txs);
      case 'year':
        return _buildYearTrend(range.start, txs);
      default:
        return const [0, 0, 0];
    }
  }

  Future<List<_TrendTx>> _getTransactionsForRange(
    Database db,
    _DateRange range,
    String type,
    String category,
  ) async {
    final whereCategory = category == 'Tümü' ? '' : 'AND c.name = ?';
    final args = <Object?>[
      type,
      range.start.toIso8601String(),
      range.end.toIso8601String(),
      if (category != 'Tümü') category,
    ];

    final result = await db.rawQuery('''
      SELECT
        t.amount,
        t.transaction_date
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ?
        AND t.transaction_date >= ?
        AND t.transaction_date < ?
        $whereCategory
      ORDER BY t.transaction_date ASC
      ''', args);

    return result.map((e) {
      return _TrendTx(
        amount: (e['amount'] as num).toDouble(),
        date: DateTime.parse(e['transaction_date'] as String),
      );
    }).toList();
  }

  List<double> _buildDayTrend(DateTime start, List<_TrendTx> txs) {
    final buckets = List<double>.filled(6, 0.0);

    for (final tx in txs) {
      final hour = tx.date.hour;
      final bucket = (hour / 4).floor().clamp(0, 5);
      buckets[bucket] += tx.amount;
    }

    return _normalizeTrend(buckets);
  }

  List<double> _buildWeekTrend(DateTime start, List<_TrendTx> txs) {
    final buckets = List<double>.filled(7, 0.0);

    for (final tx in txs) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diff = dateOnly
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (diff >= 0 && diff < 7) {
        buckets[diff] += tx.amount;
      }
    }

    return _normalizeTrend(buckets);
  }

  List<double> _buildMonthTrend(
    DateTime start,
    DateTime end,
    List<_TrendTx> txs,
  ) {
    final totalDays = end.difference(start).inDays;
    final buckets = List<double>.filled(totalDays, 0.0);

    for (final tx in txs) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diff = dateOnly
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (diff >= 0 && diff < totalDays) {
        buckets[diff] += tx.amount;
      }
    }

    return _normalizeTrend(buckets);
  }

  List<double> _buildYearTrend(DateTime start, List<_TrendTx> txs) {
    final buckets = List<double>.filled(12, 0.0);

    for (final tx in txs) {
      final diffMonth =
          (tx.date.year - start.year) * 12 + (tx.date.month - start.month);
      if (diffMonth >= 0 && diffMonth < 12) {
        buckets[diffMonth] += tx.amount;
      }
    }

    return _normalizeTrend(buckets);
  }

  List<double> _normalizeTrend(List<double> values) {
    if (values.isEmpty) return const [0, 0, 0];

    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) {
      return List<double>.filled(values.length, 0.0);
    }

    return values.map((e) => e / max).toList();
  }

  _DateRange _resolveRange(AnalyticsParams params) {
    final anchor = params.anchor;

    switch (params.range) {
      case 'day':
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        final end = start.add(const Duration(days: 1));
        return _DateRange(start, end);

      case 'week':
        final start = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
        ).subtract(Duration(days: anchor.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return _DateRange(start, end);

      case 'month':
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 1);
        return _DateRange(start, end);

      case 'year':
        final start = DateTime(anchor.year, 1, 1);
        final end = DateTime(anchor.year + 1, 1, 1);
        return _DateRange(start, end);

      default:
        throw Exception('Invalid range');
    }
  }

  _DateRange _resolvePreviousRange(AnalyticsParams params) {
    final anchor = params.anchor;

    switch (params.range) {
      case 'day':
        return _resolveRange(
          params.copyWith(anchor: anchor.subtract(const Duration(days: 1))),
        );
      case 'week':
        return _resolveRange(
          params.copyWith(anchor: anchor.subtract(const Duration(days: 7))),
        );
      case 'month':
        return _resolveRange(
          params.copyWith(anchor: DateTime(anchor.year, anchor.month - 1, 1)),
        );
      case 'year':
        return _resolveRange(
          params.copyWith(anchor: DateTime(anchor.year - 1, 1, 1)),
        );
      default:
        throw Exception('Invalid range');
    }
  }

  double _calculateAverage({
    required double total,
    required String range,
    required DateTime anchor,
  }) {
    switch (range) {
      case 'day':
        return total;
      case 'week':
        return total / 7;
      case 'month':
        final days = DateUtils.getDaysInMonth(anchor.year, anchor.month);
        return total / days;
      case 'year':
        return total / 12;
      default:
        return total;
    }
  }

  (String, String) _buildInsight(
    double current,
    double prev,
    List<AnalyticsBreakdownItem> breakdown,
    String mode,
  ) {
    if (current == 0) {
      return ('Bu dönem veri yok.', 'Yeni kayıt ekledikçe analiz oluşur.');
    }

    if (breakdown.isNotEmpty) {
      final top = breakdown.first;
      return (
        '${top.name} en yüksek paya sahip',
        '%${(top.pct * 100).toStringAsFixed(1)} oranında.',
      );
    }

    return ('Analiz hazır', 'Detayları inceleyebilirsin.');
  }

  (String, String) _buildSuggestion(double current, double prev, String mode) {
    if (prev == 0) {
      return ('Karşılaştırma yok', 'Yeni dönem başlangıcı.');
    }

    final diff = current - prev;
    final pct = (diff / prev * 100).abs();

    if (diff > 0) {
      return (
        mode == 'expense' ? 'Harcamalar arttı' : 'Gelir arttı',
        '%${pct.toStringAsFixed(1)} artış',
      );
    } else if (diff < 0) {
      return (
        mode == 'expense' ? 'Harcamalar azaldı' : 'Gelir azaldı',
        '%${pct.toStringAsFixed(1)} düşüş',
      );
    }

    return ('Değişim yok', 'Aynı seviyede.');
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  _DateRange(this.start, this.end);
}

class _TrendTx {
  final double amount;
  final DateTime date;

  _TrendTx({required this.amount, required this.date});
}
