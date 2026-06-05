import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Secondary metric row: accent icon chip + label + progress bar + value
/// (used for HRV, Stress, Air Quality, etc. on metric detail screens).
class ProgressMetricRow extends StatelessWidget {
  const ProgressMetricRow({
    required this.icon,
    required this.label,
    required this.progress,
    required this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final double progress;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.accentColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF15161C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.monoStyle(
                  12.5,
                  FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 7,
                  backgroundColor: tokens.track,
                  valueColor: AlwaysStoppedAnimation(tokens.accentColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          trailing,
          style: AppTypography.monoStyle(
            13,
            FontWeight.w700,
            color: tokens.textMuted,
          ),
        ),
      ],
    );
  }
}
