import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Horizontal week selector. Decorative selection (no per-day backend data);
/// future days are disabled. Defaults to today.
class DateStrip extends StatelessWidget {
  const DateStrip({required this.selected, required this.onSelect, super.key});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i - 5)));

    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return Row(
      children: days.map((day) {
        final isSelected = same(day, selected);
        final isFuture = day.isAfter(today);
        return Expanded(
          child: GestureDetector(
            onTap: isFuture ? null : () => onSelect(day),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? tokens.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: AppTypography.monoStyle(
                      11,
                      FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF15161C)
                          : tokens.textMuted.withValues(
                              alpha: isFuture ? 0.4 : 1,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: AppTypography.monoStyle(
                      14,
                      FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF15161C)
                          : onSurface.withValues(alpha: isFuture ? 0.4 : 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
