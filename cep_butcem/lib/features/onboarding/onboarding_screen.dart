import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLastPage => _index == onboardingPages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) => setState(() => _index = i);

  void _goToSetupBudget() {
    context.go('/setup-budget');
  }

  void _handlePrimaryButton() {
    if (_isLastPage) {
      _goToSetupBudget();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.mutedDark
        : AppColors.mutedLight;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              const SizedBox(height: 8),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: _onPageChanged,
                  itemCount: onboardingPages.length,
                  itemBuilder: (context, i) {
                    final p = onboardingPages[i];
                    return _OnboardingPage(
                      title: p.title,
                      subtitle: p.subtitle,
                      imageAsset: p.imageAsset,
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(onboardingPages.length, (i) {
                  final isActive = i == _index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 18 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.indicatorActive
                          : AppColors.indicatorInactive,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              PrimaryButton(
                text: _isLastPage ? "Hemen Başla" : "Devam Et",
                onPressed: _handlePrimaryButton,
              ),

              const SizedBox(height: 12),

              if (!_isLastPage)
                GestureDetector(
                  onTap: _goToSetupBudget,
                  child: Text(
                    "Tanıtımı Geç",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),

        Expanded(
          child: Center(
            child: imageAsset == null
                ? Container(
                    width: 240,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        "İllüstrasyon\n(assets sonra)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                      ),
                    ),
                  )
                : Image.asset(imageAsset!, fit: BoxFit.contain),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 10),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.mutedDark
                : AppColors.mutedLight,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 18),
      ],
    );
  }
}
