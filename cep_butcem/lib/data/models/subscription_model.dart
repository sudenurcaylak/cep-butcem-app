enum SubscriptionProvider {
  netflix,
  youtube,
  blutv,
  other;

  String get value {
    switch (this) {
      case SubscriptionProvider.netflix:
        return 'netflix';
      case SubscriptionProvider.youtube:
        return 'youtube';
      case SubscriptionProvider.blutv:
        return 'blutv';
      case SubscriptionProvider.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionProvider.netflix:
        return 'Netflix';
      case SubscriptionProvider.youtube:
        return 'YouTube';
      case SubscriptionProvider.blutv:
        return 'BluTV';
      case SubscriptionProvider.other:
        return 'Diğer';
    }
  }

  static SubscriptionProvider fromValue(String? value) {
    switch (value) {
      case 'netflix':
        return SubscriptionProvider.netflix;
      case 'youtube':
        return SubscriptionProvider.youtube;
      case 'blutv':
        return SubscriptionProvider.blutv;
      default:
        return SubscriptionProvider.other;
    }
  }
}

enum SubscriptionPeriod {
  monthly,
  yearly;

  String get value {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return 'monthly';
      case SubscriptionPeriod.yearly:
        return 'yearly';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionPeriod.monthly:
        return 'Aylık';
      case SubscriptionPeriod.yearly:
        return 'Yıllık';
    }
  }

  static SubscriptionPeriod fromValue(String? value) {
    switch (value) {
      case 'yearly':
        return SubscriptionPeriod.yearly;
      default:
        return SubscriptionPeriod.monthly;
    }
  }
}

class SubscriptionModel {
  final int? id;
  final String name;
  final double amount;
  final int billingDay;
  final SubscriptionProvider provider;
  final SubscriptionPeriod period;
  final bool autoPay;
  final bool remindersEnabled;
  final int remindDaysBefore;
  final bool isActive;
  final String createdAt;
  final String? lastProcessedMonth;
  final int? accountId; // ✅ EKLENDİ

  const SubscriptionModel({
    this.id,
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.provider,
    required this.period,
    required this.autoPay,
    required this.remindersEnabled,
    required this.remindDaysBefore,
    required this.isActive,
    required this.createdAt,
    this.lastProcessedMonth,
    this.accountId, // ✅
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billing_day': billingDay,
      'provider': provider.value,
      'period': period.value,
      'auto_pay': autoPay ? 1 : 0,
      'reminders_enabled': remindersEnabled ? 1 : 0,
      'remind_days_before': remindDaysBefore,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'last_processed_month': lastProcessedMonth,
      'account_id': accountId, // ✅
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      billingDay: map['billing_day'] as int,
      provider: SubscriptionProvider.fromValue(map['provider'] as String?),
      period: SubscriptionPeriod.fromValue(map['period'] as String?),
      autoPay: (map['auto_pay'] as int? ?? 0) == 1,
      remindersEnabled: (map['reminders_enabled'] as int? ?? 0) == 1,
      remindDaysBefore: map['remind_days_before'] as int? ?? 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      lastProcessedMonth: map['last_processed_month'] as String?,
      accountId: map['account_id'] as int?, // ✅
    );
  }

  SubscriptionModel copyWith({
    int? id,
    String? name,
    double? amount,
    int? billingDay,
    SubscriptionProvider? provider,
    SubscriptionPeriod? period,
    bool? autoPay,
    bool? remindersEnabled,
    int? remindDaysBefore,
    bool? isActive,
    String? createdAt,
    String? lastProcessedMonth,
    int? accountId, // ✅
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingDay: billingDay ?? this.billingDay,
      provider: provider ?? this.provider,
      period: period ?? this.period,
      autoPay: autoPay ?? this.autoPay,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastProcessedMonth: lastProcessedMonth ?? this.lastProcessedMonth,
      accountId: accountId ?? this.accountId, // ✅
    );
  }

  DateTime nextDueDate(DateTime now) {
    int safeDay(int year, int month, int targetDay) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return targetDay.clamp(1, lastDay);
    }

    if (period == SubscriptionPeriod.monthly) {
      final thisMonthDay = safeDay(now.year, now.month, billingDay);
      final currentMonthDue = DateTime(now.year, now.month, thisMonthDay);

      if (!currentMonthDue.isBefore(DateTime(now.year, now.month, now.day))) {
        return currentMonthDue;
      }

      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextMonthDay = safeDay(nextMonth.year, nextMonth.month, billingDay);
      return DateTime(nextMonth.year, nextMonth.month, nextMonthDay);
    } else {
      final thisYearDay = safeDay(now.year, 1, billingDay);
      final currentYearDue = DateTime(now.year, 1, thisYearDay);

      if (!currentYearDue.isBefore(DateTime(now.year, now.month, now.day))) {
        return currentYearDue;
      }

      final nextYearDay = safeDay(now.year + 1, 1, billingDay);
      return DateTime(now.year + 1, 1, nextYearDay);
    }
  }
}
