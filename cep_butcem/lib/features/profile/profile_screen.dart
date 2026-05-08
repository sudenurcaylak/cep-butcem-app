import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../core/state/profile_store.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  static const Color _purple = Color(0xFF6C4DFF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final store = ProfileScope.of(context);
    final profile = store.value;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: profile.fullName,
                  onEdit: () async {
                    final result = await context.push<ProfileData>(
                      ProfileEditScreen.route,
                      extra: profile,
                    );

                    if (result != null) {
                      store.setProfile(result);
                    }
                  },
                ),
                const SizedBox(height: 36),
                _MenuCard(
                  isDark: isDark,
                  children: [
                    _MenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: const Color(0xFFE9E3FF),
                      iconColor: _purple,
                      title: 'Hesap',
                      onTap: () {
                        context.push('/account');
                      },
                    ),
                    _DividerLine(isDark: isDark),
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      iconBg: const Color(0xFFEDEDED),
                      iconColor: const Color(0xFF7A7A7A),
                      title: 'Ayarlar',
                      onTap: () {
                        context.push('/settings');
                      },
                    ),
                    _DividerLine(isDark: isDark),
                    _MenuItem(
                      icon: Icons.support_agent_rounded,
                      iconBg: const Color(0xFFE7F7FF),
                      iconColor: const Color(0xFF2196F3),
                      title: 'Destek & Bilgi',
                      onTap: () {
                        context.push('/support');
                      },
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9B6BFF),
                    Color(0xFF6C4DFF),
                    Color(0xFF4B2DCC),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C4DFF).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF232634)
                        : const Color(0xFFF1EDFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232634) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white12 : const Color(0xFFE6E6F3),
      ),
    );
  }
}
