import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/brand_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 108)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
              const SizedBox(height: 26),
              Text(
                'Stealthera',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 450.ms),
              const SizedBox(height: 8),
              Text(
                'Health signals, quietly guarded',
                style: theme.textTheme.bodyMedium,
              ).animate().fadeIn(delay: 340.ms, duration: 450.ms),
              const SizedBox(height: 30),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
