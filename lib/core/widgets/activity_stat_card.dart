import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// A wide activity card (Steps / Calories): icon chip + big value + unit, with
/// a soft accent gradient "blob" bleeding in from the right.
class ActivityStatCard extends StatelessWidget {
  const ActivityStatCard({
    required this.icon,
    required this.value,
    required this.unit,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String value;
  final String unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: tokens.elevatedCard,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 84,
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -20,
                bottom: -20,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        tokens.blob.first.withValues(alpha: 0.0),
                        tokens.blob.first.withValues(alpha: 0.9),
                        tokens.blob.last,
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(120),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: tokens.accentColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      value,
                      style: AppTypography.monoStyle(
                        26,
                        FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        unit,
                        style: AppTypography.monoStyle(
                          14,
                          FontWeight.w400,
                          color: tokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
