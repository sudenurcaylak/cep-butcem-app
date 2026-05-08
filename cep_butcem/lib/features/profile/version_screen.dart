import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_background.dart';

class VersionScreen extends StatelessWidget {
  const VersionScreen({super.key});

  static const routePath = '/settings/version';

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
                  title: 'Sürüm',
                  onBack: () => context.pop(),
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Uygulama Bilgisi', isDark: isDark),
                const SizedBox(height: 10),
                _VersionCard(
                  isDark: isDark,
                  children: const [
                    _VersionInfoRow(label: 'Uygulama', value: 'Cep Bütçem'),
                    _VersionDivider(),
                    _VersionInfoRow(label: 'Sürüm', value: 'v1.0.0'),
                    _VersionDivider(),
                    _VersionInfoRow(label: 'Durum', value: 'İlk sürüm'),
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

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.children, required this.isDark});

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

class _VersionInfoRow extends StatelessWidget {
  const _VersionInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionDivider extends StatelessWidget {
  const _VersionDivider();

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
