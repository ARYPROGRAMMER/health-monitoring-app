import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label, this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

/// Rounded floating pill navigation (Home / Alerts / Settings).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.paddingOf(context).bottom * 0.5,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: tokens.elevatedCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: tokens.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: tokens.isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final item = items[i];
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? tokens.accentColor
                              : tokens.textMuted,
                          size: 26,
                        ),
                        if (item.badge > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: tokens.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tokens.elevatedCard,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 18 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: tokens.accentColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
