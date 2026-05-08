import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/budget_setup_data.dart';
import '../../data/repositories/budget_repository.dart';

class SetupBudgetScreen extends StatefulWidget {
  const SetupBudgetScreen({super.key});

  @override
  State<SetupBudgetScreen> createState() => _SetupBudgetScreenState();
}

class _SetupBudgetScreenState extends State<SetupBudgetScreen> {
  final _bank = TextEditingController();
  final _wallet = TextEditingController();

  final BudgetRepository _budgetRepository = BudgetRepository();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budget = await _budgetRepository.getBudget();

      if (budget != null) {
        _bank.text = _formatNumber(budget.bankAmount);
        _wallet.text = _formatNumber(budget.walletAmount);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bütçe yüklenirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  double? _parseAmount(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _saveBudget() async {
    final bankAmount = _parseAmount(_bank.text);
    final walletAmount = _parseAmount(_wallet.text);

    if (bankAmount == null || walletAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen banka ve cüzdan için geçerli bir tutar gir.'),
        ),
      );
      return;
    }

    if (bankAmount < 0 || walletAmount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tutarlar negatif olamaz.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final budget = BudgetSetupData(
        bankAmount: bankAmount,
        walletAmount: walletAmount,
        createdAt: now,
        updatedAt: now,
      );

      await _budgetRepository.saveBudget(budget);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bütçe kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _bank.dispose();
    _wallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Bütçeni\nOluşturalım',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bütçeni banka ve cüzdan olarak ayırarak\nharcamalarını daha net takip edebilirsin.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Banka',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      AuthTextField(
                        controller: _bank,
                        hint: '₺',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Cüzdan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      AuthTextField(
                        controller: _wallet,
                        hint: '₺',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: _isSaving ? 'Kaydediliyor...' : 'Hemen Başla',
                        onPressed: _isSaving ? null : _saveBudget,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Daha sonra Hesap Sayfası’ndan değiştirebilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
