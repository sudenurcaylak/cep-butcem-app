import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';

class EditSubscriptionScreen extends StatefulWidget {
  const EditSubscriptionScreen({super.key, required this.subscription});

  static const routePath = '/subscriptions/edit';

  final SubscriptionModel subscription;

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  static const Color _purple = Color(0xFF6C4DFF);

  final SubscriptionRepository _repository = SubscriptionRepository();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;

  late SubscriptionProvider _provider;
  late SubscriptionPeriod _period;

  late int _billingDay;
  late bool _autoPay;
  late bool _remind;
  late int _remindDaysBefore;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    final sub = widget.subscription;

    _nameCtrl = TextEditingController(text: sub.name);
    _amountCtrl = TextEditingController(text: sub.amount.toStringAsFixed(2));

    _provider = sub.provider;
    _period = sub.period;
    _billingDay = sub.billingDay;
    _autoPay = sub.autoPay;
    _remind = sub.remindersEnabled;
    _remindDaysBefore = sub.remindDaysBefore;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isDeleting;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                _TopBar(title: 'Abonelik Düzenle', onBack: () => context.pop()),
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
                          onChanged: isBusy
                              ? null
                              : (v) =>
                                    setState(() => _provider = v ?? _provider),
                        ),
                        const SizedBox(height: 18),

                        const _FieldLabel('Abonelik adı'),
                        TextField(
                          controller: _nameCtrl,
                          enabled: !isBusy,
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
                          enabled: !isBusy,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Örn: 149.99',
                            border: UnderlineInputBorder(),
                          ),
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
                          onChanged: isBusy
                              ? null
                              : (v) => setState(() => _period = v ?? _period),
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
                          onChanged: isBusy
                              ? null
                              : (v) => setState(
                                  () => _billingDay = v ?? _billingDay,
                                ),
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
                              onChanged: isBusy
                                  ? null
                                  : (v) => setState(() => _autoPay = v),
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
                              onChanged: isBusy
                                  ? null
                                  : (v) => setState(() => _remind = v),
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
                            onChanged: isBusy
                                ? null
                                : (v) => setState(
                                    () => _remindDaysBefore =
                                        v ?? _remindDaysBefore,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      PrimaryButton(
                        text: _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                        backgroundColor: _purple,
                        onPressed: isBusy ? null : _onSave,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isBusy ? null : _onDeletePressed,
                        child: Text(
                          _isDeleting ? 'Siliniyor...' : 'Aboneliği Sil',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = widget.subscription.copyWith(
        name: name,
        amount: amount,
        billingDay: _billingDay,
        provider: _provider,
        period: _period,
        autoPay: _autoPay,
        remindersEnabled: _remind,
        remindDaysBefore: _remindDaysBefore,
      );

      await _repository.updateSubscription(updated);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abonelik güncellenirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _onDeletePressed() async {
    final subscriptionId = widget.subscription.id;
    if (subscriptionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Aboneliği sil',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '"${widget.subscription.name}" silinsin mi?',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _repository.deleteSubscription(subscriptionId);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abonelik silinirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
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
