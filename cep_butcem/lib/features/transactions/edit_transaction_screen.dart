import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _transactionRepo = TransactionRepository();
  final _accountRepo = AccountRepository();

  List<AccountModel> _accounts = [];
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();

    _amountCtrl.text = widget.transaction.amount.toString();
    _noteCtrl.text = widget.transaction.note ?? '';
    _selectedAccountId = widget.transaction.accountId;

    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final data = await _accountRepo.getAll();
    setState(() => _accounts = data);
  }

  AccountModel? _getAccount(int? id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateTransaction() async {
    final newAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    final oldTx = widget.transaction;

    final oldAccount = _getAccount(oldTx.accountId);
    final newAccount = _getAccount(_selectedAccountId);

    if (oldAccount == null || newAccount == null) return;

    // 🔥 1. eski etkiyi geri al
    final oldBalance = oldTx.type == 'expense'
        ? oldAccount.balance + oldTx.amount
        : oldAccount.balance - oldTx.amount;

    await _accountRepo.updateBalance(
      accountId: oldAccount.id!,
      newBalance: oldBalance,
    );

    // 🔥 2. yeni etkiyi uygula
    final newBalance = oldTx.type == 'expense'
        ? newAccount.balance - newAmount
        : newAccount.balance + newAmount;

    await _accountRepo.updateBalance(
      accountId: newAccount.id!,
      newBalance: newBalance,
    );

    // 🔥 3. transaction update
    final updated = oldTx.copyWith(
      amount: newAmount,
      accountId: _selectedAccountId,
      note: _noteCtrl.text,
    );

    await _transactionRepo.updateTransaction(updated);

    if (!mounted) return;
    context.pop(true);
  }

  Future<void> _deleteTransaction() async {
    final tx = widget.transaction;
    final account = _getAccount(tx.accountId);

    if (account == null) return;

    // 🔥 geri alma
    final newBalance = tx.type == 'expense'
        ? account.balance + tx.amount
        : account.balance - tx.amount;

    await _accountRepo.updateBalance(
      accountId: account.id!,
      newBalance: newBalance,
    );

    await _transactionRepo.deleteTransaction(tx.id!);

    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tutar'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              items: _accounts
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
              decoration: const InputDecoration(labelText: 'Hesap'),
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateTransaction,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
