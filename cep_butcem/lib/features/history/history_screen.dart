import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/transaction_repository.dart';

enum HistorySort { newest, oldest, amountHigh, amountLow }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionRepository _repository = TransactionRepository();

  int _tabIndex = 0;
  HistorySort _sort = HistorySort.newest;

  final Set<String> _selectedCategories = {};

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;

  static const List<String> _expenseCategories = [
    'Market',
    'Giyim',
    'Kafe',
    'Eğitim',
    'Ev',
    'Abonelikler',
    'Sağlık',
    'Spor',
    'Sosyal',
    'Ulaşım',
    'Hediye',
    'Diğer',
  ];

  static const List<String> _incomeCategories = [
    'Maaş',
    'Hediye',
    'Faiz',
    'Diğer',
  ];

  List<String> _availableCategories(bool isExpenseTab) =>
      isExpenseTab ? _expenseCategories : _incomeCategories;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final data = await _repository.getAllTransactions();

      if (!mounted) return;
      setState(() {
        _allTransactions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hareketler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _openEditTransaction(TransactionModel tx) async {
    final result = await context.push<bool>('/transactions/edit', extra: tx);

    if (result == true) {
      await _loadTransactions();
    }
  }

  void _showDeleteDialog(TransactionModel tx) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('İşlemi Sil'),
          content: const Text('Bu işlemi silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _deleteTransaction(tx);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    if (tx.id == null) return;

    try {
      final accountRepo = AccountRepository();

      if (tx.accountId != null) {
        final accounts = await accountRepo.getAll();
        final matched = accounts.where((a) => a.id == tx.accountId);

        if (matched.isNotEmpty) {
          final account = matched.first;

          final newBalance = tx.type == 'expense'
              ? account.balance + tx.amount
              : account.balance - tx.amount;

          await accountRepo.updateBalance(
            accountId: account.id!,
            newBalance: newBalance,
          );
        }
      }

      await _repository.deleteTransaction(tx.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İşlem silindi')));

      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem silinirken hata oluştu: $e')),
      );
    }
  }

  List<TransactionModel> _buildFilteredList(bool isExpenseTab) {
    final type = isExpenseTab ? 'expense' : 'income';

    final filtered = _allTransactions.where((tx) => tx.type == type).toList();

    if (_selectedCategories.isNotEmpty) {
      filtered.removeWhere((tx) => !_selectedCategories.contains(tx.title));
    }

    filtered.sort((a, b) {
      switch (_sort) {
        case HistorySort.newest:
          return b.transactionDate.compareTo(a.transactionDate);
        case HistorySort.oldest:
          return a.transactionDate.compareTo(b.transactionDate);
        case HistorySort.amountHigh:
          return b.amount.compareTo(a.amount);
        case HistorySort.amountLow:
          return a.amount.compareTo(b.amount);
      }
    });

    return filtered;
  }

  String _sortLabel(HistorySort s) {
    switch (s) {
      case HistorySort.newest:
        return 'Yeniden Eskiye';
      case HistorySort.oldest:
        return 'Eskiden Yeniye';
      case HistorySort.amountHigh:
        return 'Tutar (Azalan)';
      case HistorySort.amountLow:
        return 'Tutar (Artan)';
    }
  }

  void _openSortSheet(Color accent) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.35),
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sıralama',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              _SheetOption(
                title: 'Yeniden Eskiye',
                selected: _sort == HistorySort.newest,
                onTap: () => _setSort(ctx, HistorySort.newest),
                accent: accent,
              ),
              _SheetOption(
                title: 'Eskiden Yeniye',
                selected: _sort == HistorySort.oldest,
                onTap: () => _setSort(ctx, HistorySort.oldest),
                accent: accent,
              ),
              _SheetOption(
                title: 'Tutar (Azalan)',
                selected: _sort == HistorySort.amountHigh,
                onTap: () => _setSort(ctx, HistorySort.amountHigh),
                accent: accent,
              ),
              _SheetOption(
                title: 'Tutar (Artan)',
                selected: _sort == HistorySort.amountLow,
                onTap: () => _setSort(ctx, HistorySort.amountLow),
                accent: accent,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _setSort(BuildContext sheetContext, HistorySort s) {
    Navigator.pop(sheetContext);
    setState(() => _sort = s);
  }

  void _openCategoryFilterDialog(bool isExpenseTab, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final categories = _availableCategories(isExpenseTab);
    final temp = {..._selectedCategories};

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                    maxHeight: 420,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kategori Filtrele',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.pop(dialogCtx),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _FilterTile(
                              title: 'Tümü',
                              selected: temp.isEmpty,
                              accent: accent,
                              onTap: () => setDialogState(() => temp.clear()),
                            ),
                            const SizedBox(height: 8),
                            for (final c in categories) ...[
                              _FilterTile(
                                title: c,
                                selected: temp.contains(c),
                                accent: accent,
                                onTap: () {
                                  setDialogState(() {
                                    if (temp.contains(c)) {
                                      temp.remove(c);
                                    } else {
                                      temp.add(c);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setDialogState(() => temp.clear()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Temizle',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                setState(() {
                                  _selectedCategories
                                    ..clear()
                                    ..addAll(temp);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Uygula',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList() {
    final isExpenseTab = _tabIndex == 0;
    final items = _buildFilteredList(isExpenseTab);

    if (items.isEmpty) {
      return _EmptyState(isExpenseTab: isExpenseTab);
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 10, bottom: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final tx = items[i];

          return GestureDetector(
            onTap: () => _openEditTransaction(tx),
            onLongPress: () => _showDeleteDialog(tx),
            child: _GlassHistoryCard(tx: tx),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final purple = cs.primary;
    final lilacBg = isDark ? const Color(0xFF221B3D) : const Color(0xFFEFE9FF);

    final isExpenseTab = _tabIndex == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                _TopBar(
                  tabIndex: _tabIndex,
                  onTabChanged: (i) {
                    setState(() {
                      _tabIndex = i;
                      _selectedCategories.clear();
                    });
                  },
                  onBack: () => context.go('/dashboard'),
                  lilacBg: lilacBg,
                  purple: purple,
                ),
                const SizedBox(height: 12),
                _SortFilterRow(
                  sortLabel: _sortLabel(_sort),
                  onSortTap: () => _openSortSheet(purple),
                  onFilterTap: () {
                    _openCategoryFilterDialog(isExpenseTab, purple);
                  },
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.tabIndex,
    required this.onTabChanged,
    required this.lilacBg,
    required this.purple,
  });

  final VoidCallback onBack;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final Color lilacBg;
  final Color purple;

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
        const SizedBox(width: 10),
        Expanded(
          child: _PurpleSegmentTabs(
            index: tabIndex,
            onChanged: onTabChanged,
            lilacBg: lilacBg,
            purple: purple,
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _PurpleSegmentTabs extends StatelessWidget {
  const _PurpleSegmentTabs({
    required this.index,
    required this.onChanged,
    required this.lilacBg,
    required this.purple,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final Color lilacBg;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: lilacBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PurpleSegButton(
              text: 'Giderler',
              active: index == 0,
              purple: purple,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _PurpleSegButton(
              text: 'Gelirler',
              active: index == 1,
              purple: purple,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurpleSegButton extends StatelessWidget {
  const _PurpleSegButton({
    required this.text,
    required this.active,
    required this.purple,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color purple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? purple : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: active ? Colors.white : purple,
          ),
        ),
      ),
    );
  }
}

class _SortFilterRow extends StatelessWidget {
  const _SortFilterRow({
    required this.sortLabel,
    required this.onSortTap,
    required this.onFilterTap,
  });

  final String sortLabel;
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        InkWell(
          onTap: onSortTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.swap_vert_rounded, size: 18, color: onSurface),
                const SizedBox(width: 6),
                Text(
                  sortLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.tune_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _GlassHistoryCard extends StatelessWidget {
  const _GlassHistoryCard({required this.tx});
  final TransactionModel tx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isExpense = tx.type == 'expense';
    final sign = isExpense ? '-' : '+';

    final glassColor = cs.surface.withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.78 : 0.88,
    );

    final iconBg = isExpense
        ? const Color(0xFFFFE0CC)
        : const Color(0xFFDFF7E6);

    final icon = isExpense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF333333)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.note ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign₺${_formatAmount(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(tx.transactionDate),
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  static String _formatAmount(double n) {
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }

    return buf.toString();
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: accent)
          : Icon(
              Icons.circle_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
            ),
      onTap: onTap,
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? accent.withOpacity(0.18)
        : cs.surface.withOpacity(0.60);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? accent : cs.onSurface.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isExpenseTab});
  final bool isExpenseTab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        isExpenseTab ? 'Henüz gider yok.' : 'Henüz gelir yok.',
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
