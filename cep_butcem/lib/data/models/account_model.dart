import 'package:flutter/material.dart';

class AccountModel {
  final int? id;
  final String name;
  final double balance;
  final int iconCode;
  final int colorValue;
  final String createdAt;

  AccountModel({
    this.id,
    required this.name,
    required this.balance,
    required this.iconCode,
    required this.colorValue,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      balance: (map['balance'] as num).toDouble(),
      iconCode: map['icon_code'],
      colorValue: map['color_value'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'icon_code': iconCode,
      'color_value': colorValue,
      'created_at': createdAt,
    };
  }

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
}
