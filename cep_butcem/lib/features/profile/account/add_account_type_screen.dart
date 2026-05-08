import 'package:flutter/material.dart';

import '/../core/theme/app_background.dart';
import '/../core/widgets/primary_button.dart';
import '/../data/models/account_model.dart';
import '/../data/repositories/account_repository.dart';

class AddAccountTypeScreen extends StatefulWidget {
  const AddAccountTypeScreen({super.key});

  static const routePath = '/account/add';

  @override
  State<AddAccountTypeScreen> createState() => _AddAccountTypeScreenState();
}

class _AddAccountTypeScreenState extends State<AddAccountTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _repository = AccountRepository();

  IconData? _selectedIcon;
  bool _isSaving = false;

  final List<IconData> _icons = const [
    Icons.account_balance_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.credit_card_rounded,
    Icons.savings_rounded,
    Icons.payments_rounded,
    Icons.wallet_rounded,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  int _resolveColorValue(IconData icon) {
    if (icon == Icons.account_balance_rounded) {
      return const Color(0xFF2F6BFF).value;
    }
    if (icon == Icons.account_balance_wallet_rounded) {
      return const Color(0xFF20B45B).value;
    }
    if (icon == Icons.credit_card_rounded) {
      return const Color(0xFFFF8A00).value;
    }
    if (icon == Icons.savings_rounded) {
      return const Color(0xFFFF3B57).value;
    }
    if (icon == Icons.payments_rounded) {
      return const Color(0xFF6C4DFF).value;
    }
    if (icon == Icons.wallet_rounded) {
      return const Color(0xFFE3E0FF).value;
    }

    return const Color(0xFF6C4DFF).value;
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _isSaving) return;

    final name = _nameCtrl.text.trim();
    final amount = _parseAmount(_amountCtrl.text);
    final icon = _selectedIcon ?? Icons.account_balance_wallet_rounded;

    setState(() => _isSaving = true);

    try {
      final account = AccountModel(
        name: name,
        balance: amount,
        iconCode: icon.codePoint,
        colorValue: _resolveColorValue(icon),
        createdAt: DateTime.now().toIso8601String(),
      );

      await _repository.insert(account);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hesap eklenemedi.')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Hesap Türü Ekle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

              return SingleChildScrollView(
                physics: keyboardOpen
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          _FieldCard(
                            label: 'Hesap Türü Giriniz',
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(color: Colors.white),
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                'Örn: Nakit, Maaş, Birikim',
                              ),
                              validator: (v) {
                                final text = (v ?? '').trim();
                                if (text.isEmpty) {
                                  return 'Hesap türü boş olamaz';
                                }
                                if (text.length < 2) {
                                  return 'En az 2 karakter gir';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          _FieldCard(
                            label: 'Tutar Giriniz',
                            child: TextFormField(
                              controller: _amountCtrl,
                              style: const TextStyle(color: Colors.white),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              decoration: _inputDecoration('Örn: 10000'),
                              validator: (v) {
                                final amount = _parseAmount(v ?? '');
                                if (amount <= 0) {
                                  return 'Geçerli bir tutar gir';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'İkon Seçiniz (opsiyonel)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _icons.map((ic) {
                              final selected = _selectedIcon == ic;
                              return _IconChip(
                                icon: ic,
                                selected: selected,
                                onTap: () => setState(() => _selectedIcon = ic),
                              );
                            }).toList(),
                          ),

                          const Spacer(),

                          PrimaryButton(
                            text: _isSaving ? 'Ekleniyor...' : 'Ekle',
                            onPressed: _isSaving ? null : _submit,
                          ),

                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(.35)),
      filled: true,
      fillColor: const Color(0xFF232634),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.85),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3E0FF) : const Color(0xFF232634),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF6C63FF) : Colors.white10,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? const Color(0xFF0B1020) : Colors.white70,
        ),
      ),
    );
  }
}
