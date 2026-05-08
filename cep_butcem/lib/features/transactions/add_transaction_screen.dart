import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AccountRepository _accountRepository = AccountRepository();

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  static const int _noteMax = 200;

  DateTime _selectedDate = DateTime.now();

  bool _showAllCategories = false;
  bool _isSaving = false;
  bool _isLoadingCategories = true;
  bool _isLoadingAccounts = true;

  List<AccountModel> _accounts = [];
  int? _selectedAccountId;

  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];

  int? _selectedExpenseCategoryId;
  int? _selectedIncomeCategoryId;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadAccounts(), _loadCategories()]);
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoadingAccounts = true);

    try {
      final accounts = await _accountRepository.getAll();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;

        if (_accounts.isNotEmpty) {
          final bankAccounts = _accounts.where(
            (a) => a.name.toLowerCase().contains('banka'),
          );

          _selectedAccountId = bankAccounts.isNotEmpty
              ? bankAccounts.first.id
              : _accounts.first.id;
        }

        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingAccounts = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hesaplar yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final expense = await _categoryRepository.getCategoriesByType('expense');
      final income = await _categoryRepository.getCategoriesByType('income');

      if (!mounted) return;

      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingCategories = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoriler yüklenirken hata oluştu: $e')),
      );
    }
  }

  bool get _hasAmount {
    final text = _amountCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text);
    return value != null && value > 0;
  }

  bool get _canSubmit {
    return _selectedAccountId != null &&
        _hasAmount &&
        !_isSaving &&
        !_isLoadingAccounts;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Tarih seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _openCalculator() async {
    final current =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalculatorSheet(initialValue: current),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _amountCtrl.text = result.toStringAsFixed(2));
    }
  }

  AccountModel? _selectedAccountModel() {
    if (_selectedAccountId == null) return null;

    try {
      return _accounts.firstWhere((a) => a.id == _selectedAccountId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyAccountBalance({
    required AccountModel account,
    required double amount,
    required bool isExpense,
  }) async {
    final newBalance = isExpense
        ? account.balance - amount
        : account.balance + amount;

    await _accountRepository.updateBalance(
      accountId: account.id!,
      newBalance: newBalance,
    );
  }

  Future<void> _submit({required bool isExpense}) async {
    if (!_canSubmit) return;

    final account = _selectedAccountModel();

    if (account == null || account.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir hesap seç.')),
      );
      return;
    }

    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    final selectedCategoryId = isExpense
        ? _selectedExpenseCategoryId
        : _selectedIncomeCategoryId;

    final categories = isExpense ? _expenseCategories : _incomeCategories;

    CategoryModel? selectedCategory;
    if (selectedCategoryId != null) {
      try {
        selectedCategory = categories.firstWhere(
          (c) => c.id == selectedCategoryId,
        );
      } catch (_) {
        selectedCategory = null;
      }
    }

    final noteText = _noteCtrl.text.trim();

    final title =
        selectedCategory?.name ?? (isExpense ? 'Gider İşlemi' : 'Gelir İşlemi');

    final transaction = TransactionModel(
      title: title,
      amount: amount,
      type: isExpense ? 'expense' : 'income',
      categoryId: selectedCategory?.id,
      accountId: account.id,
      note: noteText.isEmpty ? null : noteText,
      transactionDate: _selectedDate.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() => _isSaving = true);

    try {
      await _transactionRepository.insertTransaction(transaction);

      await _applyAccountBalance(
        account: account,
        amount: amount,
        isExpense: isExpense,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isExpense ? "Gider" : "Gelir"} kaydedildi'),
          duration: const Duration(milliseconds: 900),
        ),
      );

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Color(0xB3FFFFFF),
                          indicatorColor: Colors.white,
                          indicatorWeight: 2,
                          labelStyle: TextStyle(fontWeight: FontWeight.w900),
                          tabs: [
                            Tab(text: 'Giderler'),
                            Tab(text: 'Gelirler'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildForm(isExpense: true),
                        _buildForm(isExpense: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isExpense}) {
    final list = isExpense ? _expenseCategories : _incomeCategories;
    final selectedCategoryId = isExpense
        ? _selectedExpenseCategoryId
        : _selectedIncomeCategoryId;

    const collapsedCount = 8;
    final catsToShow = _showAllCategories
        ? List<CategoryModel>.from(list)
        : list.take(collapsedCount).toList();

    final hasMore = list.length > collapsedCount;
    final gridCount = catsToShow.length + (hasMore ? 1 : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontWeight: FontWeight.w800,
                      ),
                      prefixText: 'TRY  ',
                      prefixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openCalculator,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.calculate_rounded,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Hesap:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(zorunlu)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: _isLoadingAccounts
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: LinearProgressIndicator(),
                  )
                : _accounts.isEmpty
                ? Text(
                    'Önce Hesaplar sayfasından hesap oluşturmalısın.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedAccountId,
                      dropdownColor: const Color(0xFF141826),
                      iconEnabledColor: Colors.white.withOpacity(0.9),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      items: _accounts
                          .map(
                            (a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text(
                                '${a.name} - ${a.balance.toStringAsFixed(2)} ₺',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Kategoriler:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(opsiyonel)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (selectedCategoryId != null)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (isExpense) {
                        _selectedExpenseCategoryId = null;
                      } else {
                        _selectedIncomeCategoryId = null;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      'Seçimi kaldır',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _GlassCard(
            child: _isLoadingCategories
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.9,
                        ),
                    itemBuilder: (context, i) {
                      if (hasMore && i == catsToShow.length) {
                        return _MoreTile(
                          expanded: _showAllCategories,
                          onTap: () => setState(
                            () => _showAllCategories = !_showAllCategories,
                          ),
                        );
                      }

                      final c = catsToShow[i];
                      final isSelected = selectedCategoryId == c.id;

                      return _CategoryOnlyIconTile(
                        category: c,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isExpense) {
                              _selectedExpenseCategoryId = isSelected
                                  ? null
                                  : c.id;
                            } else {
                              _selectedIncomeCategoryId = isSelected
                                  ? null
                                  : c.id;
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tarih:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yorum ekle:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _noteCtrl,
                  maxLength: _noteMax,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Yorum',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_noteCtrl.text.length}/$_noteMax',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Opacity(
            opacity: _canSubmit ? 1 : 0.6,
            child: PrimaryButton(
              text: _isSaving ? 'Kaydediliyor...' : 'Ekle',
              onPressed: _canSubmit
                  ? () => _submit(isExpense: isExpense)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF141826).withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CategoryOnlyIconTile extends StatelessWidget {
  const _CategoryOnlyIconTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fgColor = category.colorValue != null
        ? Color(category.colorValue!)
        : Colors.white;

    final bgColor = category.colorValue != null
        ? Color(category.colorValue!).withOpacity(0.18)
        : Colors.white.withOpacity(0.10);

    final iconData = category.iconCode != null
        ? IconData(category.iconCode!, fontFamily: 'MaterialIcons')
        : Icons.category_rounded;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.white.withOpacity(0.95)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(iconData, color: fgColor, size: 26),
              ),
              if (selected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.more_horiz_rounded,
              color: Colors.white.withOpacity(0.92),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dahası',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet({required this.initialValue});

  final double initialValue;

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  String _expr = '';
  String _display = '0';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != 0) {
      _expr = widget.initialValue.toStringAsFixed(2);
      _display = _expr;
    }
  }

  void _tap(String v) {
    setState(() {
      if (_display == '0' && RegExp(r'^\d$').hasMatch(v)) {
        _display = v;
        _expr = v;
      } else {
        _expr += v;
        _display = _expr;
      }
    });
  }

  void _clear() {
    setState(() {
      _expr = '';
      _display = '0';
    });
  }

  void _backspace() {
    if (_expr.isEmpty) return;
    setState(() {
      _expr = _expr.substring(0, _expr.length - 1);
      _display = _expr.isEmpty ? '0' : _expr;
    });
  }

  void _op(String op) {
    setState(() {
      if (_expr.isEmpty) {
        _expr = '0$op';
      } else {
        if (RegExp(r'[+\-×÷]$').hasMatch(_expr)) {
          _expr = _expr.substring(0, _expr.length - 1) + op;
        } else {
          _expr += op;
        }
      }
      _display = _expr;
    });
  }

  double _eval(String expr) {
    expr = expr.replaceAll(' ', '');
    if (expr.isEmpty) return 0;
    expr = expr.replaceAll(',', '.');

    List<String> tokens = [];
    String num = '';

    for (int i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if ('0123456789.'.contains(ch)) {
        num += ch;
      } else if ('+-×÷'.contains(ch)) {
        if (num.isEmpty && (ch == '-' || ch == '+')) {
          num = ch;
        } else {
          tokens.add(num);
          tokens.add(ch);
          num = '';
        }
      }
    }

    if (num.isNotEmpty) {
      tokens.add(num);
    }

    tokens = tokens.where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 0;

    final pass = <dynamic>[];
    pass.add(double.tryParse(tokens[0]) ?? 0.0);

    for (int i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) break;

      final op = tokens[i];
      final right = double.tryParse(tokens[i + 1]) ?? 0.0;

      if (op == '×' || op == '÷') {
        final left = pass.removeLast() as double;
        final res = op == '×'
            ? (left * right)
            : (right == 0 ? 0.0 : left / right);
        pass.add(res);
      } else {
        pass.add(op);
        pass.add(right);
      }
    }

    double acc = pass.first as double;
    for (int i = 1; i < pass.length; i += 2) {
      if (i + 1 >= pass.length) break;
      final op = pass[i] as String;
      final right = pass[i + 1] as double;
      acc = op == '+' ? (acc + right) : (acc - right);
    }

    return acc;
  }

  void _equals() {
    final v = _eval(_expr);
    setState(() {
      _expr = v.toStringAsFixed(2);
      _display = _expr;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141826).withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Hesap Makinesi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Text(
                      _display,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      _CalcKey(text: 'C', onTap: _clear, strong: true),
                      _CalcKey(
                        icon: Icons.backspace_outlined,
                        onTap: _backspace,
                      ),
                      _CalcKey(text: '÷', onTap: () => _op('÷'), op: true),
                      _CalcKey(text: '×', onTap: () => _op('×'), op: true),
                      _CalcKey(text: '7', onTap: () => _tap('7')),
                      _CalcKey(text: '8', onTap: () => _tap('8')),
                      _CalcKey(text: '9', onTap: () => _tap('9')),
                      _CalcKey(text: '-', onTap: () => _op('-'), op: true),
                      _CalcKey(text: '4', onTap: () => _tap('4')),
                      _CalcKey(text: '5', onTap: () => _tap('5')),
                      _CalcKey(text: '6', onTap: () => _tap('6')),
                      _CalcKey(text: '+', onTap: () => _op('+'), op: true),
                      _CalcKey(text: '1', onTap: () => _tap('1')),
                      _CalcKey(text: '2', onTap: () => _tap('2')),
                      _CalcKey(text: '3', onTap: () => _tap('3')),
                      _CalcKey(text: '=', onTap: _equals, strong: true),
                      _CalcKey(text: '0', onTap: () => _tap('0'), wide: true),
                      _CalcKey(text: '.', onTap: () => _tap('.')),
                      _CalcKey(
                        text: 'Kullan',
                        onTap: () {
                          final v = _eval(_expr);
                          Navigator.of(context).pop(v);
                        },
                        strong: true,
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
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    this.text,
    this.icon,
    required this.onTap,
    this.op = false,
    this.strong = false,
    this.wide = false,
  });

  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool op;
  final bool strong;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final bg = strong
        ? Colors.white.withOpacity(0.16)
        : op
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: icon != null
            ? Icon(icon, color: Colors.white.withOpacity(0.92))
            : Text(
                text ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
