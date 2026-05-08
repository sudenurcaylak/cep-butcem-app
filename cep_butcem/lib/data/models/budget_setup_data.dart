class BudgetSetupData {
  final int? id;
  final double bankAmount;
  final double walletAmount;
  final String createdAt;
  final String? updatedAt;

  const BudgetSetupData({
    this.id,
    required this.bankAmount,
    required this.walletAmount,
    required this.createdAt,
    this.updatedAt,
  });

  double get totalBudget => bankAmount + walletAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_balance': bankAmount,
      'wallet_balance': walletAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BudgetSetupData.fromMap(Map<String, dynamic> map) {
    return BudgetSetupData(
      id: map['id'] as int?,
      bankAmount: (map['bank_balance'] as num?)?.toDouble() ?? 0,
      walletAmount: (map['wallet_balance'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  BudgetSetupData copyWith({
    int? id,
    double? bankAmount,
    double? walletAmount,
    String? createdAt,
    String? updatedAt,
  }) {
    return BudgetSetupData(
      id: id ?? this.id,
      bankAmount: bankAmount ?? this.bankAmount,
      walletAmount: walletAmount ?? this.walletAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
