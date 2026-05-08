import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '/data/models/subscription_model.dart';

class CreateSubscriptionScreen extends StatefulWidget {
  const CreateSubscriptionScreen({super.key});

  @override
  State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  static const Color _purple = Color(0xFF6C4DFF);

  final SubscriptionRepository _repository = SubscriptionRepository();
  final AccountRepository _accountRepository = AccountRepository();

  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final List<AccountModel> _accounts = [];

  SubscriptionProvider _provider = SubscriptionProvider.netflix;
  SubscriptionPeriod _period = SubscriptionPeriod.monthly;

  int _billingDay = 1;
  int? _selectedAccountId;

  bool _autoPay = true;
  bool _remind = false;
  int _remindDaysBefore = 2;

  bool _isLoadingAccounts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountRepository.getAll();

      if (!mounted) return;

      setState(() {
        _accounts
          ..clear()
          ..addAll(accounts);

        if (_accounts.isNotEmpty) {
          final bank = _accounts.where(
            (a) => a.name.toLowerCase().contains('banka'),
          );

          _selectedAccountId = bank.isNotEmpty
              ? bank.first.id
              : _accounts.first.id;
        }

        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAccounts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hesaplar yüklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(title: 'Abonelik Ekle', onBack: () => context.pop()),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('Servis'),
                        DropdownButtonFormField<SubscriptionProvider>(
                          value: _provider,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          items: SubscriptionProvider.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _provider = v ?? _provider),
                        ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Abonelik adı'),
                        TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Örn: Netflix, YouTube Premium',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Tutar (₺)'),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Örn: 149.99',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Hangi hesaptan düşsün?'),
                        if (_isLoadingAccounts)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          )
                        else if (_accounts.isEmpty)
                          const Text(
                            'Önce Hesaplar sayfasından Banka veya Cüzdan hesabı oluşturmalısın.',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          DropdownButtonFormField<int>(
                            value: _selectedAccountId,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                            ),
                            items: _accounts
                                .map(
                                  (account) => DropdownMenuItem(
                                    value: account.id,
                                    child: Text(
                                      '${account.name} - ${account.balance.toStringAsFixed(2)} ₺',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedAccountId = v),
                          ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Periyot'),
                        DropdownButtonFormField<SubscriptionPeriod>(
                          value: _period,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          items: SubscriptionPeriod.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _period = v ?? _period),
                        ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Ödeme günü (1–28)'),
                        DropdownButtonFormField<int>(
                          value: _billingDay,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          items: List.generate(28, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text('$d'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _billingDay = v ?? _billingDay),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Otomatik Ödeme',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2A2A2A),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _autoPay,
                              onChanged: (v) => setState(() => _autoPay = v),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Hatırlat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2A2A2A),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _remind,
                              onChanged: (v) => setState(() => _remind = v),
                            ),
                          ],
                        ),

                        if (_remind) ...[
                          const SizedBox(height: 10),
                          const _FieldLabel('Kaç gün önce hatırlatsın?'),
                          DropdownButtonFormField<int>(
                            value: _remindDaysBefore,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                            ),
                            items: [1, 2, 3, 5, 7]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text('$d gün önce'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _remindDaysBefore = v ?? _remindDaysBefore,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                    backgroundColor: _purple,
                    onPressed: _isSaving ? null : _onCreate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreate() async {
    final name = _nameCtrl.text.trim().isEmpty
        ? _provider.label
        : _nameCtrl.text.trim();

    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar gir.')));
      return;
    }

    if (_autoPay && _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Otomatik ödeme için bir hesap seçmelisin.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final model = SubscriptionModel(
        name: name,
        amount: amount,
        billingDay: _billingDay,
        provider: _provider,
        period: _period,
        autoPay: _autoPay,
        remindersEnabled: _remind,
        remindDaysBefore: _remindDaysBefore,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        lastProcessedMonth: null,
        accountId: _selectedAccountId,
      );

      await _repository.insertSubscription(model);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abonelik kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8A8A8A),
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}
