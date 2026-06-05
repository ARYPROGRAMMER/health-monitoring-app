import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// A tile in the dashboard metric grid: a circular glyph + label.
class MetricGridTile extends StatelessWidget {
  const MetricGridTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.comingSoon = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final tileColor = Color.alphaBlend(
      tokens.accentColor.withValues(alpha: comingSoon ? 0.04 : 0.10),
      tokens.card,
    );
    final fg = comingSoon ? tokens.textMuted : tokens.accentColor;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.isDark ? Colors.black : Colors.white,
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Icon(comingSoon ? Icons.help_outline_rounded : icon,
                    size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoStyle(
                    13,
                    FontWeight.w400,
                    color: comingSoon
                        ? tokens.textMuted
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
