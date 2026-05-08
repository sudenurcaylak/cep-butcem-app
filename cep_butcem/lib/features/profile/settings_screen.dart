import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import 'theme_settings_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'version_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  title: 'Ayarlar',
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),

                _SectionTitle(title: 'Genel', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _StaticSettingItem(
                      icon: Icons.dark_mode_rounded,
                      iconBg: const Color(0xFFEDE7FF),
                      iconColor: const Color(0xFF6C4DFF),
                      title: 'Tema',
                      subtitle: 'Koyu Mod',
                      onTap: () => context.push(ThemeSettingsScreen.routePath),
                    ),
                    const _SettingsDivider(),
                    _StaticSettingItem(
                      icon: Icons.language_rounded,
                      iconBg: const Color(0xFFE8F7FF),
                      iconColor: const Color(0xFF2196F3),
                      title: 'Dil',
                      subtitle: 'Türkçe',
                      onTap: () =>
                          context.push(LanguageSettingsScreen.routePath),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Bildirimler', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _StaticSettingItem(
                      icon: Icons.notifications_active_rounded,
                      iconBg: const Color(0xFFFFF1E6),
                      iconColor: const Color(0xFFFF8A00),
                      title: 'Bildirim Ayarları',
                      subtitle: 'Hatırlatıcı ve abonelik bildirimleri',
                      onTap: () =>
                          context.push(NotificationSettingsScreen.routePath),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Uygulama', isDark: isDark),
                const SizedBox(height: 10),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _StaticSettingItem(
                      icon: Icons.security_rounded,
                      iconBg: const Color(0xFFFFEEF1),
                      iconColor: const Color(0xFFE45B78),
                      title: 'Gizlilik',
                      subtitle: 'Veriler cihazında saklanır',
                      onTap: () => context.push(PrivacyScreen.routePath),
                    ),
                    const _SettingsDivider(),
                    _StaticSettingItem(
                      icon: Icons.info_outline_rounded,
                      iconBg: const Color(0xFFEDEDED),
                      iconColor: const Color(0xFF7A7A7A),
                      title: 'Sürüm',
                      subtitle: 'Cep Bütçem v1.0.0',
                      onTap: () => context.push(VersionScreen.routePath),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.isDark,
  });

  final String title;
  final VoidCallback onBack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.isDark});

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

class _StaticSettingItem extends StatelessWidget {
  const _StaticSettingItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : const Color(0xFFB0B0B0),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
