import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_background.dart';
import '../../data/models/analytics_data.dart';
import '../../data/models/analytics_params.dart';
import '../../data/repositories/analytics_repository.dart';
import 'analytics_store.dart';

enum AnalyticsRange { day, week, month, year }

enum AnalyticsMode { expense, income }

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalyticsStore(repository: AnalyticsRepository()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  final PageController _pageCtrl = PageController();

  int _pageIndex = 0;
  bool _showSwipeHint = true;

  AnalyticsMode _mode = AnalyticsMode.expense;
  AnalyticsRange _range = AnalyticsRange.day;

  DateTime _anchor = DateTime.now();
  String _category = 'Tümü';

  static const List<String> _expenseCats = [
    'Tümü',
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

  static const List<String> _incomeCats = [
    'Tümü',
    'Maaş',
    'Hediye',
    'Faiz',
    'Diğer',
  ];

  List<String> get _cats =>
      _mode == AnalyticsMode.expense ? _expenseCats : _incomeCats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    final store = context.read<AnalyticsStore>();

    await store.load(
      AnalyticsParams(
        mode: _mode == AnalyticsMode.expense ? 'expense' : 'income',
        range: switch (_range) {
          AnalyticsRange.day => 'day',
          AnalyticsRange.week => 'week',
          AnalyticsRange.month => 'month',
          AnalyticsRange.year => 'year',
        },
        anchor: _anchor,
        category: _category,
      ),
    );

    if (!mounted) return;

    if (store.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(store.error!)));
    }
  }

  void _updateMode(AnalyticsMode mode) {
    setState(() {
      _mode = mode;
      _category = 'Tümü';
    });
    _loadAnalytics();
  }

  void _updateCategory(String value) {
    setState(() => _category = value);
    _loadAnalytics();
  }

  void _updateRange(AnalyticsRange range) {
    setState(() => _range = range);
    _loadAnalytics();
  }

  void _goPrev() {
    setState(() => _anchor = _shift(_anchor, _range, -1));
    _loadAnalytics();
  }

  void _goNext() {
    setState(() => _anchor = _shift(_anchor, _range, 1));
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AnalyticsStore>();
    final stats = store.data;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final purple = cs.primary;
    final lilacBg = isDark ? const Color(0xFF221B3D) : const Color(0xFFEFE9FF);

    final subtitle = _subtitle(_range, _anchor, _category);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      mode: _mode,
                      isDark: isDark,
                      onModeChanged: _updateMode,
                      onBack: () => context.pop(),
                      onExport: () {},
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CategoryDropdown(
                          value: _category,
                          items: _cats,
                          isDark: isDark,
                          onChanged: _updateCategory,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _RangeTabs(
                      value: _range,
                      onChanged: _updateRange,
                      lilac: isDark ? const Color(0xFF232634) : lilacBg,
                      orange: const Color(0xFFFF9A57),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _DateNavigator(
                      label: _rangeLabel(_range, _anchor),
                      isDark: isDark,
                      onPrev: _goPrev,
                      onNext: _goNext,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: store.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAnalytics,
                        child: Stack(
                          children: [
                            PageView(
                              controller: _pageCtrl,
                              onPageChanged: (i) => setState(() {
                                _pageIndex = i;
                                _showSwipeHint = false;
                              }),
                              children: [
                                _AnalyticsPageScroll(
                                  child: _LinePageContent(
                                    purple: purple,
                                    subtitle: subtitle,
                                    points: stats.trendPointsNormalized,
                                    isDark: isDark,
                                    totalText:
                                        'Toplam: ₺${_fmtMoney(stats.total)}',
                                    avgText:
                                        'Ortalama: ₺${_fmtMoney(stats.average)}',
                                    cardBg: lilacBg,
                                    cardStroke: purple,
                                    breakdownAll: stats.breakdownAll,
                                  ),
                                ),
                                _AnalyticsPageScroll(
                                  child: _DonutPageContent(
                                    subtitle: subtitle,
                                    isDark: isDark,
                                    segments: stats.donutSegments,
                                    totalText: '₺${_fmtMoney(stats.total)}',
                                    cardBg: lilacBg,
                                    cardStroke: purple,
                                    insightText: stats.insightText,
                                    insightSubText: stats.insightSubText,
                                    breakdownAll: stats.breakdownAll,
                                  ),
                                ),
                                _AnalyticsPageScroll(
                                  child: _ComparePageContent(
                                    purple: purple,
                                    subtitle: subtitle,
                                    currentLabel: _currentLabel(_range),
                                    prevLabel: _prevLabel(_range),
                                    isDark: isDark,
                                    currentValue: stats.currentTotal,
                                    prevValue: stats.prevTotal,
                                    cardBg: lilacBg,
                                    cardStroke: purple,
                                    suggestionText: stats.suggestionText,
                                    suggestionSubText: stats.suggestionSubText,
                                  ),
                                ),
                              ],
                            ),
                            if (_showSwipeHint)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 78,
                                child: Center(
                                  child: _SwipeHint(purple: purple),
                                ),
                              ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 10,
                              child: IgnorePointer(
                                ignoring: true,
                                child: _Dots(
                                  count: 3,
                                  index: _pageIndex,
                                  active: purple,
                                  isDark: isDark,
                                ),
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

  String _subtitle(AnalyticsRange r, DateTime d, String cat) {
    final c = cat == 'Tümü' ? 'Tüm kategoriler' : cat;
    return '$c • ${_rangeLabel(r, d)}';
  }

  String _rangeLabel(AnalyticsRange r, DateTime d) {
    switch (r) {
      case AnalyticsRange.day:
        return '${d.day} ${_monthTr(d.month)}';
      case AnalyticsRange.week:
        final start = _startOfWeek(d);
        final end = start.add(const Duration(days: 6));
        return '${start.day} ${_monthTr(start.month)} - ${end.day} ${_monthTr(end.month)}';
      case AnalyticsRange.month:
        return _monthTr(d.month);
      case AnalyticsRange.year:
        return '${d.year}';
    }
  }

  DateTime _shift(DateTime d, AnalyticsRange r, int dir) {
    switch (r) {
      case AnalyticsRange.day:
        return d.add(Duration(days: dir));
      case AnalyticsRange.week:
        return d.add(Duration(days: 7 * dir));
      case AnalyticsRange.month:
        return DateTime(d.year, d.month + dir, math.min(d.day, 28));
      case AnalyticsRange.year:
        return DateTime(d.year + dir, d.month, d.day);
    }
  }

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  String _monthTr(int m) {
    const months = [
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
    return months[m - 1];
  }

  String _currentLabel(AnalyticsRange r) {
    switch (r) {
      case AnalyticsRange.day:
        return 'Bugün';
      case AnalyticsRange.week:
        return 'Bu hafta';
      case AnalyticsRange.month:
        return 'Bu ay';
      case AnalyticsRange.year:
        return 'Bu yıl';
    }
  }

  String _prevLabel(AnalyticsRange r) {
    switch (r) {
      case AnalyticsRange.day:
        return 'Dün';
      case AnalyticsRange.week:
        return 'Geçen hafta';
      case AnalyticsRange.month:
        return 'Geçen ay';
      case AnalyticsRange.year:
        return 'Geçen yıl';
    }
  }

  String _fmtMoney(double n) {
    final rounded = n.round();
    final s = rounded.abs().toString();
    final buf = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }

    return rounded < 0 ? '-${buf.toString()}' : buf.toString();
  }
}

class _AnalyticsPageScroll extends StatelessWidget {
  const _AnalyticsPageScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
      child: child,
    );
  }
}

class _LinePageContent extends StatelessWidget {
  const _LinePageContent({
    required this.purple,
    required this.subtitle,
    required this.points,
    required this.isDark,
    required this.totalText,
    required this.avgText,
    required this.cardBg,
    required this.cardStroke,
    required this.breakdownAll,
  });

  final Color purple;
  final String subtitle;
  final List<double> points;
  final bool isDark;
  final String totalText;
  final String avgText;
  final Color cardBg;
  final Color cardStroke;
  final List<AnalyticsBreakdownItem> breakdownAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(title: 'Trend', subtitle: subtitle, isDark: isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: _LineChart(
                  points: points.isEmpty ? const [0, 0, 0] : points,
                  line: purple,
                  grid: isDark ? Colors.white12 : const Color(0xFFEAEAF3),
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 12),
              _MiniStatRow(left: totalText, right: avgText, isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                title: 'Kategori Detayı',
                subtitle: 'Tüm kategoriler',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              if (breakdownAll.isEmpty)
                Text(
                  'Bu dönem kategori verisi yok.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                for (int i = 0; i < breakdownAll.length; i++) ...[
                  _BreakdownRow(
                    name: breakdownAll[i].name,
                    pct: breakdownAll[i].pct,
                    amount: breakdownAll[i].amount,
                    color: breakdownAll[i].color,
                    isDark: isDark,
                  ),
                  if (i != breakdownAll.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPageContent extends StatelessWidget {
  const _DonutPageContent({
    required this.subtitle,
    required this.isDark,
    required this.segments,
    required this.totalText,
    required this.cardBg,
    required this.cardStroke,
    required this.insightText,
    required this.insightSubText,
    required this.breakdownAll,
  });

  final String subtitle;
  final bool isDark;
  final List<AnalyticsDonutSegment> segments;
  final String totalText;
  final Color cardBg;
  final Color cardStroke;
  final String insightText;
  final String insightSubText;
  final List<AnalyticsBreakdownItem> breakdownAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(title: 'Dağılım', subtitle: subtitle, isDark: isDark),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 190,
                      child: _DonutChart(
                        totalText: totalText,
                        segments: segments,
                        ringBg: isDark
                            ? Colors.white12
                            : const Color(0xFFEAEAF3),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendRow(
                          color: segments[0].color,
                          text: segments[0].name,
                          pct:
                              '${(segments[0].value * 100).toStringAsFixed(1)}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _LegendRow(
                          color: segments[1].color,
                          text: segments[1].name,
                          pct:
                              '${(segments[1].value * 100).toStringAsFixed(1)}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _LegendRow(
                          color: segments[2].color,
                          text: segments[2].name,
                          pct:
                              '${(segments[2].value * 100).toStringAsFixed(1)}%',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (breakdownAll.isEmpty)
                Text(
                  'Bu dönem kategori verisi yok.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                for (int i = 0; i < breakdownAll.length; i++) ...[
                  _BreakdownRow(
                    name: breakdownAll[i].name,
                    pct: breakdownAll[i].pct,
                    amount: breakdownAll[i].amount,
                    color: breakdownAll[i].color,
                    isDark: isDark,
                  ),
                  if (i != breakdownAll.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(title: 'İçgörü', subtitle: 'Bu dönem', isDark: isDark),
              const SizedBox(height: 10),
              Text(
                insightText,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                insightSubText,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparePageContent extends StatelessWidget {
  const _ComparePageContent({
    required this.purple,
    required this.subtitle,
    required this.currentLabel,
    required this.prevLabel,
    required this.isDark,
    required this.currentValue,
    required this.prevValue,
    required this.cardBg,
    required this.cardStroke,
    required this.suggestionText,
    required this.suggestionSubText,
  });

  final Color purple;
  final String subtitle;
  final String currentLabel;
  final String prevLabel;
  final bool isDark;
  final double currentValue;
  final double prevValue;
  final Color cardBg;
  final Color cardStroke;
  final String suggestionText;
  final String suggestionSubText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: _ComparePro(
            purple: purple,
            subtitle: subtitle,
            currentLabel: currentLabel,
            prevLabel: prevLabel,
            currentValue: currentValue,
            prevValue: prevValue,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          isDark: isDark,
          bg: cardBg,
          stroke: cardStroke,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                title: 'Öneri',
                subtitle: 'Kısa aksiyon',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Text(
                suggestionText,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                suggestionSubText,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.isDark,
    required this.onModeChanged,
    required this.onBack,
    required this.onExport,
  });

  final AnalyticsMode mode;
  final bool isDark;
  final ValueChanged<AnalyticsMode> onModeChanged;
  final VoidCallback onBack;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AnalyticsMode>(
                value: mode,
                dropdownColor: isDark ? const Color(0xFF232634) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: isDark ? Colors.white : null,
                ),
                items: [
                  DropdownMenuItem(
                    value: AnalyticsMode.expense,
                    child: Text(
                      'Giderler',
                      style: TextStyle(color: isDark ? Colors.white : null),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AnalyticsMode.income,
                    child: Text(
                      'Gelirler',
                      style: TextStyle(color: isDark ? Colors.white : null),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) onModeChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232634) : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF232634) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.expand_more_rounded,
            color: isDark ? Colors.white : null,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(color: isDark ? Colors.white : null),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.value,
    required this.onChanged,
    required this.lilac,
    required this.orange,
    required this.isDark,
  });

  final AnalyticsRange value;
  final ValueChanged<AnalyticsRange> onChanged;
  final Color lilac;
  final Color orange;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: lilac,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _RangeChip(
            text: 'Gün',
            active: value == AnalyticsRange.day,
            onTap: () => onChanged(AnalyticsRange.day),
            orange: orange,
            isDark: isDark,
          ),
          _RangeChip(
            text: 'Hafta',
            active: value == AnalyticsRange.week,
            onTap: () => onChanged(AnalyticsRange.week),
            orange: orange,
            isDark: isDark,
          ),
          _RangeChip(
            text: 'Ay',
            active: value == AnalyticsRange.month,
            onTap: () => onChanged(AnalyticsRange.month),
            orange: orange,
            isDark: isDark,
          ),
          _RangeChip(
            text: 'Yıl',
            active: value == AnalyticsRange.year,
            onTap: () => onChanged(AnalyticsRange.year),
            orange: orange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.text,
    required this.active,
    required this.onTap,
    required this.orange,
    required this.isDark,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;
  final Color orange;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? orange : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF6B6B6B)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPrev,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white : null,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : null,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onNext,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.isDark,
    required this.bg,
    required this.stroke,
  });

  final Widget child;
  final bool isDark;
  final Color bg;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232634) : bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: stroke.withOpacity(isDark ? 0.28 : 0.35),
          width: 1.2,
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
      ],
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.left,
    required this.right,
    required this.isDark,
  });

  final String left;
  final String right;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          left,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.active,
    required this.isDark,
  });

  final int count;
  final int index;
  final Color active;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: on
                ? active
                : (isDark ? Colors.white24 : const Color(0xFFBDBDBD)),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.purple});

  final Color purple;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_rounded, color: purple, size: 18),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Yana kaydır',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.name,
    required this.pct,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  final String name;
  final double pct;
  final double amount;
  final Color color;
  final bool isDark;

  String _fmt(double n) {
    final rounded = n.round();
    final s = rounded.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return rounded < 0 ? '-${buf.toString()}' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$name  ${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
            ),
            Text(
              '₺${_fmt(amount)}',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: pct.clamp(0, 1),
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFEAEAF3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.points,
    required this.line,
    required this.grid,
    required this.isDark,
  });

  final List<double> points;
  final Color line;
  final Color grid;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        points: points,
        line: line,
        grid: grid,
        isDark: isDark,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.line,
    required this.grid,
    required this.isDark,
  });

  final List<double> points;
  final Color line;
  final Color grid;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    final bg = Paint()
      ..color = isDark ? const Color(0xFF1C1F2B) : const Color(0xFFF7F7F9);
    canvas.drawRRect(r, bg);

    final padding = 16.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding + (h / 4) * i;
      canvas.drawLine(Offset(padding, y), Offset(padding + w, y), gp);
    }

    if (points.length < 2) return;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = padding + (w / (points.length - 1)) * i;
      final y = padding + (1 - points[i].clamp(0.0, 1.0)) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final lp = Paint()
      ..color = line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, lp);

    final dp = Paint()..color = line;
    for (int i = 0; i < points.length; i++) {
      final x = padding + (w / (points.length - 1)) * i;
      final y = padding + (1 - points[i].clamp(0.0, 1.0)) * h;
      canvas.drawCircle(Offset(x, y), 4.5, dp);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.line != line ||
        oldDelegate.grid != grid ||
        oldDelegate.isDark != isDark;
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.totalText,
    required this.ringBg,
    required this.isDark,
  });

  final List<AnalyticsDonutSegment> segments;
  final String totalText;
  final Color ringBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(
        segments: segments,
        ringBg: ringBg,
        isDark: isDark,
      ),
      child: Center(
        child: Text(
          totalText,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.ringBg,
    required this.isDark,
  });

  final List<AnalyticsDonutSegment> segments;
  final Color ringBg;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    final bg = Paint()
      ..color = isDark ? const Color(0xFF1C1F2B) : const Color(0xFFF7F7F9);
    canvas.drawRRect(r, bg);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final stroke = 18.0;

    final base = Paint()
      ..color = ringBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base);

    double start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.value.clamp(0.0, 1.0)) * 2 * math.pi;
      final p = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.ringBg != ringBg ||
        oldDelegate.isDark != isDark;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.text,
    required this.pct,
    required this.isDark,
  });

  final Color color;
  final String text;
  final String pct;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        Text(
          pct,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ComparePro extends StatelessWidget {
  const _ComparePro({
    required this.purple,
    required this.subtitle,
    required this.currentLabel,
    required this.prevLabel,
    required this.currentValue,
    required this.prevValue,
    required this.isDark,
  });

  final Color purple;
  final String subtitle;
  final String currentLabel;
  final String prevLabel;
  final double currentValue;
  final double prevValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final diff = currentValue - prevValue;
    final up = diff >= 0;
    final pct = prevValue == 0 ? 100 : ((diff / prevValue) * 100).round();
    final chipText = '${up ? '+' : ''}₺${_fmt(diff)} (%$pct) ${up ? '↑' : '↓'}';

    final maxValue = math.max(currentValue, prevValue);
    final double cRatio = maxValue == 0 ? 0.0 : currentValue / maxValue;
    final double pRatio = maxValue == 0 ? 0.0 : prevValue / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardTitle(title: 'Karşılaştırma', subtitle: subtitle, isDark: isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: purple.withOpacity(isDark ? 0.22 : 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: purple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chipText,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _BarCompareRow(
          label: currentLabel,
          ratio: cRatio,
          color: purple,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _BarCompareRow(
          label: prevLabel,
          ratio: pRatio,
          color: const Color(0xFFB9B2FF),
          isDark: isDark,
        ),
      ],
    );
  }

  String _fmt(double n) {
    final rounded = n.round();
    final neg = rounded < 0;
    final s = rounded.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }
}

class _BarCompareRow extends StatelessWidget {
  const _BarCompareRow({
    required this.label,
    required this.ratio,
    required this.color,
    required this.isDark,
  });

  final String label;
  final double ratio;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio.clamp(0, 1),
              backgroundColor: isDark
                  ? Colors.white12
                  : const Color(0xFFEAEAF3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
