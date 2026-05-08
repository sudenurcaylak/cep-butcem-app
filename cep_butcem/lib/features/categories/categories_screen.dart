import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_background.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();

  int _tab = 0; // 0: expense, 1: income
  bool _isLoading = true;

  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final expense = await _categoryRepository.getCategoriesByType('expense');
      final income = await _categoryRepository.getCategoriesByType('income');

      if (!mounted) return;

      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoriler yüklenirken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _expenseCategories : _incomeCategories;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                    const Expanded(
                      child: Text(
                        'Kategoriler',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _UnderlineTab(
                        text: 'GİDERLER',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    Expanded(
                      child: _UnderlineTab(
                        text: 'GELİR',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                      ? const Center(
                          child: Text(
                            'Kategori bulunamadı',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  childAspectRatio: 0.9,
                                ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final c = list[i];
                              return _CategoryTile(
                                category: c,
                                onTap: () {
                                  // ileride kategori düzenleme / detay
                                },
                              );
                            },
                          ),
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

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              fontSize: 12.5,
              color: Colors.white.withOpacity(selected ? 1 : 0.55),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            width: selected ? 64 : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = category.colorValue != null
        ? Color(category.colorValue!).withOpacity(0.18)
        : Colors.white.withOpacity(0.10);

    final fgColor = category.colorValue != null
        ? Color(category.colorValue!)
        : Colors.white;

    final iconData = category.iconCode != null
        ? IconData(category.iconCode!, fontFamily: 'MaterialIcons')
        : Icons.category_rounded;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(iconData, color: fgColor, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
