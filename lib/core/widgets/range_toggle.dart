import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Compact segmented control (Day / Week) used on metric detail screens.
class RangeToggle extends StatelessWidget {
  const RangeToggle({
    required this.index,
    required this.onChanged,
    this.labels = const ['Day', 'Week'],
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.elevatedCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? tokens.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                labels[i],
                style: AppTypography.monoStyle(
                  12,
                  FontWeight.w700,
                  color: selected
                      ? const Color(0xFF15161C)
                      : tokens.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
