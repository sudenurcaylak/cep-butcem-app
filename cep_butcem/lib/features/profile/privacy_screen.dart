import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/../core/theme/app_background.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const routePath = '/settings/privacy';

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
                  title: 'Gizlilik',
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Veri Kullanımı', isDark: isDark),
                const SizedBox(height: 10),
                _PrivacyCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PrivacyText(
                        text:
                            'Cep Bütçem uygulamasındaki veriler cihaz üzerinde saklanır.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _PrivacyText(
                        text:
                            'İlk sürümde backend bağlantısı, bulut senkronizasyonu veya uzak sunucuya veri gönderimi yoktur.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _PrivacyText(
                        text:
                            'İleride yeni servisler eklenirse bu sayfa güncellenebilir.',
                        isDark: isDark,
                      ),
                    ],
                  ),
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

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _PrivacyText extends StatelessWidget {
  const _PrivacyText({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.45,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF5F6368),
      ),
    );
  }
}
