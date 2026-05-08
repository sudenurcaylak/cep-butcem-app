import 'package:flutter/material.dart';

enum HistoryType { expense, income }

class HistoryItem {
  final String id;
  final HistoryType type;

  final String category; // "Giyim", "Yemek"
  final String note; // "Elbise, takı.."
  final int amount; // 2120 gibi (pozitif tut)
  final DateTime date;

  final IconData icon;
  final Color iconBg;

  HistoryItem({
    required this.id,
    required this.type,
    required this.category,
    required this.note,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconBg,
  });
}
