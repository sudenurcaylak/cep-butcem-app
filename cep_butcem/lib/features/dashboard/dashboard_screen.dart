import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_background.dart';
import 'package:cep_butcem/features/dashboard/widgets/transaction_tile.dart';

import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const route = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();

  String _month = _monthNameTr(DateTime.now().month);
  int _year = DateTime.now().year;

  bool _isLoading = true;
  List<TransactionModel> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _transactionRepository.getAllTransactions();

      if (!mounted) return;

      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard verileri yüklenirken hata oluştu: $e'),
        ),
      );
    }
  }

  List<TransactionModel> _selectedMonthTransactions() {
    final monthIndex = _monthIndexFromName(_month);

    final selectedMonthTx = _allTransactions.where((tx) {
      final d = DateTime.tryParse(tx.transactionDate);
      if (d == null) return false;
      return d.year == _year && d.month == monthIndex;
    }).toList();

    selectedMonthTx.sort((a, b) {
      return b.transactionDate.compareTo(a.transactionDate);
    });

    return selectedMonthTx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonthTx = _selectedMonthTransactions();
    final recent = selectedMonthTx.take(4).toList();

    double incomes = 0;
    double expenses = 0;

    for (final tx in selectedMonthTx) {
      final amt = tx.amount;
      if (tx.type == 'income') {
        incomes += amt;
      } else {
        expenses += amt;
      }
    }

    final balance = incomes - expenses;

    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showMonthPickerDialog(
                        context: context,
                        initialYear: _year,
                        initialMonth: _monthIndexFromName(_month),
                      );
                      if (picked == null) return;

                      setState(() {
                        _year = picked.year;
                        _month = _monthNameTr(picked.month);
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          '$_month $_year',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadDashboard,
                        child: Column(
                          children: [
                            _BalanceCard(
                              balance: balance,
                              expenses: expenses,
                              incomes: incomes,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text(
                                  'Son Hareketler',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const Spacer(),
                                if (selectedMonthTx.isNotEmpty)
                                  TextButton(
                                    onPressed: () => context.go('/history'),
                                    child: const Text('Hepsini Gör'),
                                  ),
                              ],
                            ),
                            Expanded(
                              child: selectedMonthTx.isEmpty
                                  ? const _EmptyRecentState()
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(
                                        bottom: 110,
                                      ),
                                      itemCount: recent.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        return TransactionTile(
                                          tx: recent[index],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentState extends StatelessWidget {
  const _EmptyRecentState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Henüz işlem yok',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Sağ alttaki + butonuyla ilk gelir/giderini ekleyebilirsin.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double expenses;
  final double incomes;

  const _BalanceCard({
    required this.balance,
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C4CF2), Color(0xFFB85CF6), Color(0xFFFF9A57)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Mevcut Bakiye',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '₺${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Giderler',
                  value: '₺${expenses.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Gelirler',
                  value: '₺${incomes.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alignRight;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!alignRight) ...[_IconBubble(icon), const SizedBox(width: 10)],
        Column(
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        if (alignRight) ...[const SizedBox(width: 10), _IconBubble(icon)],
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  const _IconBubble(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

Future<DateTime?> showMonthPickerDialog({
  required BuildContext context,
  required int initialYear,
  required int initialMonth,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      return _MonthPickerDialog(
        initialYear: initialYear,
        initialMonth: initialMonth,
      );
    },
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _selectedMonth;
  int _initialMonth = 1;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _initialMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF6C4CF2).withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_monthNameTr(_selectedMonth)} $_year',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _year--),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_year',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _year++),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: List.generate(12, (i) {
                final m = i + 1;

                final isInitial = m == _initialMonth;
                final isSelected = m == _selectedMonth;

                final showOutline =
                    isInitial && (_selectedMonth == _initialMonth);
                final showFill = isSelected && !showOutline;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _selectedMonth = m),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: showFill
                          ? AppColors.secondaryButton
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: showOutline
                          ? Border.all(
                              color: AppColors.secondaryButton,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Text(
                      _monthShortTr(m),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: showFill ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('İptal'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(_year, _selectedMonth, 1),
                  ),
                  child: const Text('Onayla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int _monthIndexFromName(String name) {
  const map = {
    'Ocak': 1,
    'Şubat': 2,
    'Mart': 3,
    'Nisan': 4,
    'Mayıs': 5,
    'Haziran': 6,
    'Temmuz': 7,
    'Ağustos': 8,
    'Eylül': 9,
    'Ekim': 10,
    'Kasım': 11,
    'Aralık': 12,
  };
  return map[name] ?? 1;
}

String _monthNameTr(int m) {
  const names = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return names[(m - 1).clamp(0, 11)];
}

String _monthShortTr(int m) {
  const names = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return names[(m - 1).clamp(0, 11)];
}
