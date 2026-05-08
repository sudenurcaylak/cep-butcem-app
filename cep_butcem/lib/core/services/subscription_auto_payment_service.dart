import '../../data/models/account_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class SubscriptionAutoPaymentService {
  SubscriptionAutoPaymentService._();

  static final SubscriptionAutoPaymentService instance =
      SubscriptionAutoPaymentService._();

  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final AccountRepository _accountRepository = AccountRepository();

  Future<void> processDueSubscriptions() async {
    final now = DateTime.now();

    final subscriptions = await _subscriptionRepository.getAllSubscriptions();
    final accounts = await _accountRepository.getAll();

    if (accounts.isEmpty) return;

    for (final sub in subscriptions) {
      if (!sub.isActive) continue;
      if (!sub.autoPay) continue;
      if (sub.id == null) continue;

      final paymentAccount = _selectPaymentAccount(
        accounts: accounts,
        accountId: sub.accountId,
      );

      if (paymentAccount.id == null) continue;

      final dueDate = _currentPeriodDueDate(sub, now);

      final todayOnly = DateTime(now.year, now.month, now.day);
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (dueOnly.isAfter(todayOnly)) continue;

      final processKey = _processKey(sub, dueDate);

      if (sub.lastProcessedMonth == processKey) continue;

      await _createAutoPaymentTransaction(
        sub: sub,
        account: paymentAccount,
        dueDate: dueDate,
        now: now,
      );

      await _accountRepository.updateBalance(
        accountId: paymentAccount.id!,
        newBalance: paymentAccount.balance - sub.amount,
      );

      await _subscriptionRepository.updateSubscription(
        sub.copyWith(lastProcessedMonth: processKey),
      );
    }
  }

  AccountModel _selectPaymentAccount({
    required List<AccountModel> accounts,
    required int? accountId,
  }) {
    if (accountId != null) {
      final matched = accounts.where((a) => a.id == accountId);
      if (matched.isNotEmpty) return matched.first;
    }

    return accounts.firstWhere(
      (a) => a.name.toLowerCase().contains('banka'),
      orElse: () => accounts.first,
    );
  }

  Future<void> _createAutoPaymentTransaction({
    required SubscriptionModel sub,
    required AccountModel account,
    required DateTime dueDate,
    required DateTime now,
  }) async {
    final transaction = TransactionModel(
      title: '${sub.name} abonelik ödemesi',
      amount: sub.amount,
      type: 'expense',
      categoryId: 6,
      accountId: account.id,
      note: 'Abonelik otomatik ödeme olarak işlendi.',
      transactionDate: dueDate.toIso8601String(),
      createdAt: now.toIso8601String(),
    );

    await _transactionRepository.insertTransaction(transaction);
  }

  DateTime _currentPeriodDueDate(SubscriptionModel sub, DateTime now) {
    int safeDay(int year, int month, int targetDay) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return targetDay.clamp(1, lastDay);
    }

    if (sub.period == SubscriptionPeriod.monthly) {
      final day = safeDay(now.year, now.month, sub.billingDay);
      return DateTime(now.year, now.month, day);
    }

    final day = safeDay(now.year, 1, sub.billingDay);
    return DateTime(now.year, 1, day);
  }

  String _processKey(SubscriptionModel sub, DateTime dueDate) {
    if (sub.period == SubscriptionPeriod.monthly) {
      final month = dueDate.month.toString().padLeft(2, '0');
      return '${dueDate.year}-$month';
    }

    return '${dueDate.year}';
  }
}
