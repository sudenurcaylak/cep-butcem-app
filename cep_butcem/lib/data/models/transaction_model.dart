class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' veya 'expense'
  final int? categoryId;
  final int? accountId; // ✅ EKLENDİ
  final String? note;
  final String transactionDate;
  final String createdAt;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.accountId, // ✅
    this.note,
    required this.transactionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'account_id': accountId, // ✅
      'note': note,
      'transaction_date': transactionDate,
      'created_at': createdAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int?,
      accountId: map['account_id'] as int?, // ✅
      note: map['note'] as String?,
      transactionDate: map['transaction_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    int? accountId, // ✅
    String? note,
    String? transactionDate,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId, // ✅
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
