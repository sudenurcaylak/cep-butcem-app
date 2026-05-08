import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/widgets/app_drawer.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // /dashboard
  }

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/analytics');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppColors.cardDark : Colors.white;

    return Scaffold(
      drawer: const AppDrawer(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.35),
      body: child,

      // FAB (senin tasarımındaki yuvarlak +)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 10,
          onPressed: () {
            // ✅ Yeni işlem ekranını aç
            context.push('/add-transaction');
          },
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),

      // Notch'lu bottom bar (bar hep burada kalacak)
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        child: BottomAppBar(
          color: barColor,
          elevation: 12,
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            CircleBorder(),
          ),
          notchMargin: 10,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(
                  icon: Icons.home_rounded,
                  label: 'Ana',
                  selected: currentIndex == 0,
                  onTap: () => _go(context, 0),
                ),
                _NavButton(
                  icon: Icons.history_rounded,
                  label: 'Geçmiş',
                  selected: currentIndex == 1,
                  onTap: () => _go(context, 1),
                ),

                const SizedBox(width: 44), // FAB boşluğu

                _NavButton(
                  icon: Icons.pie_chart_rounded,
                  label: 'Analiz',
                  selected: currentIndex == 2,
                  onTap: () => _go(context, 2),
                ),
                _NavButton(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  selected: currentIndex == 3,
                  onTap: () => _go(context, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
