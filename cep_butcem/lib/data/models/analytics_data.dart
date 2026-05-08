import 'package:flutter/material.dart';

class AnalyticsData {
  final double total;
  final double average;
  final List<double> trendPointsNormalized;
  final List<AnalyticsDonutSegment> donutSegments;
  final List<AnalyticsBreakdownItem> breakdownAll;
  final double currentTotal;
  final double prevTotal;
  final String insightText;
  final String insightSubText;
  final String suggestionText;
  final String suggestionSubText;

  const AnalyticsData({
    required this.total,
    required this.average,
    required this.trendPointsNormalized,
    required this.donutSegments,
    required this.breakdownAll,
    required this.currentTotal,
    required this.prevTotal,
    required this.insightText,
    required this.insightSubText,
    required this.suggestionText,
    required this.suggestionSubText,
  });

  factory AnalyticsData.empty() {
    return const AnalyticsData(
      total: 0,
      average: 0,
      trendPointsNormalized: [0, 0, 0],
      donutSegments: [
        AnalyticsDonutSegment('—', 0, Color(0xFF6C4DFF)),
        AnalyticsDonutSegment('—', 0, Color(0xFFB9B2FF)),
        AnalyticsDonutSegment('—', 0, Color(0xFFFF9A57)),
      ],
      breakdownAll: [],
      currentTotal: 0,
      prevTotal: 0,
      insightText: 'Bu dönem veri yok.',
      insightSubText: 'Yeni kayıt ekledikçe analizler oluşacak.',
      suggestionText: 'Henüz karşılaştırılacak veri yok.',
      suggestionSubText: 'Kayıt geldikçe öneriler netleşecek.',
    );
  }
}

class AnalyticsDonutSegment {
  final String name;
  final double value;
  final Color color;

  const AnalyticsDonutSegment(this.name, this.value, this.color);
}

class AnalyticsBreakdownItem {
  final String name;
  final double pct;
  final double amount;
  final Color color;

  const AnalyticsBreakdownItem({
    required this.name,
    required this.pct,
    required this.amount,
    required this.color,
  });
}
