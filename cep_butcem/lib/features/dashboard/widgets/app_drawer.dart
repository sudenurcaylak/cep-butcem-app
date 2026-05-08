import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/profile_store.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context).value;

    final fullName = '${profile.firstName} ${profile.lastName}'.trim().isEmpty
        ? 'Kullanıcı'
        : '${profile.firstName} ${profile.lastName}';

    final occupation = profile.occupation.isEmpty
        ? 'Meslek eklenmedi'
        : profile.occupation;

    return Drawer(
      backgroundColor: const Color(0xFF6C4CF2),
      child: SafeArea(
        child: Column(
          children: [
            // 🔥 PROFİL HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(
                        255,
                        20,
                        32,
                        60,
                      ).withOpacity(0.6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            39,
                            18,
                            79,
                          ).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          occupation,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withValues(alpha: 0.35)),
            ),

            const SizedBox(height: 8),

            // 📂 MENÜLER
            _DrawerItem(
              icon: Icons.category_rounded,
              title: 'Kategoriler',
              onTap: () => _nav(context, '/categories'),
            ),
            _DrawerItem(
              icon: Icons.notifications_active_rounded,
              title: 'Hatırlatıcılar',
              onTap: () => _nav(context, '/reminders'),
            ),
            _DrawerItem(
              icon: Icons.receipt_long_rounded,
              title: 'Abonelikler',
              onTap: () => _nav(context, '/subscriptions'),
            ),
            _DrawerItem(
              icon: Icons.settings_rounded,
              title: 'Ayarlar',
              onTap: () => _nav(context, '/settings'),
            ),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'Destek & Bilgi',
              onTap: () => _nav(context, '/support'),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Cep Bütçem',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, String route) {
    Navigator.pop(context);

    Future.microtask(() {
      context.push(route);
    });
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
