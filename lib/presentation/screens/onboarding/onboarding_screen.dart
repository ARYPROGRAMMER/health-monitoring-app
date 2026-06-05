import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/brand_mark.dart';

const _purple = Color(0xFF8B5CF6);

class _Page {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.fact,
    this.asset,
  });

  final String title;
  final String subtitle;
  final String fact;
  final String? asset;
}

const _pages = [
  _Page(
    title: 'Be Informed',
    subtitle: '"Stay ahead of your health with real-time insights tailored to you."',
    fact:
        'Did you know? Regular health monitoring can reduce the risk of heart disease by up to 50%.',
    asset: 'assets/illustrations/onboard_informed.png',
  ),
  _Page(
    title: 'Be Empowered',
    subtitle: '"Unlock personalized health insights to optimize your well-being."',
    fact:
        'Studies show that personalized health plans can improve fitness outcomes by 30%.',
    asset: 'assets/illustrations/onboard_empowered.png',
  ),
  _Page(
    title: 'Be in Control',
    subtitle: '"Your data, your device, your wellbeing — together in one place."',
    fact: 'Sign in to connect your wearable and start your health timeline.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: Text(
                  'Skip >>',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    visible: _index > 0,
                    onTap: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? _purple : Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ),
                  _index == _pages.length - 1
                      ? FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onDone();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Get Started'),
                        )
                      : _CircleButton(
                          icon: Icons.arrow_forward_rounded,
                          visible: true,
                          onTap: _next,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'StealthEra ',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ': ${page.title}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: _purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          Expanded(
            child: Center(
              child: page.asset != null
                  ? Image.asset(page.asset!, fit: BoxFit.contain)
                  : const _GetStartedArt(),
            ),
          ),
          Text(
            page.fact,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GetStartedArt extends StatelessWidget {
  const _GetStartedArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_purple.withValues(alpha: 0.35), Colors.transparent],
        ),
      ),
      child: const BrandMark(size: 120),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Material(
          color: _purple,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
