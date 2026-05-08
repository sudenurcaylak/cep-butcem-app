import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  static const routePath = '/settings/language';

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();

  bool _isLoading = true;
  SettingsModel _settings = SettingsModel.defaults();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _repository.getSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dil ayarları yüklenemedi: $e')));
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    try {
      await _repository.updateLanguageCode(languageCode);

      if (!mounted) return;

      setState(() {
        _settings = _settings.copyWith(languageCode: languageCode);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dil tercihi kaydedildi')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dil kaydedilemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedLanguage = _settings.languageCode;

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
                  title: 'Dil',
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Uygulama Dili', isDark: isDark),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Column(
                    children: [
                      _LanguageCard(
                        isDark: isDark,
                        children: [
                          _LanguageOptionItem(
                            icon: Icons.language_rounded,
                            iconBg: const Color(0xFFE8F7FF),
                            iconColor: const Color(0xFF2196F3),
                            title: 'Türkçe',
                            subtitle: 'Şu an kullanılan dil',
                            selected: selectedLanguage == 'tr',
                            onTap: () => _selectLanguage('tr'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'İleride İngilizce ve diğer dil seçenekleri eklenecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF7A7A7A),
                        ),
                      ),
                    ],
                  ),
                if (!_isLoading) const Spacer(),
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.children, required this.isDark});

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

class _LanguageOptionItem extends StatelessWidget {
  const _LanguageOptionItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
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
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF2196F3)
                  : (isDark ? Colors.white24 : const Color(0xFFB0B0B0)),
            ),
          ],
        ),
      ),
    );
  }
}
