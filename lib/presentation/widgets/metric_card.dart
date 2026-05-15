import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/health_models.dart';
import 'glass_panel.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.reading,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final HealthReadingModel? reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
          padding: const EdgeInsets.all(18),
          borderRadius: 22,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const Spacer(),
                    Text(
                      reading == null
                          ? 'Waiting'
                          : _relativeTime(reading!.recordedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: reading == null
                      ? Text(
                          '--',
                          key: ValueKey('$title-empty'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : RichText(
                          key: ValueKey(
                            '$title-${reading!.value}-${reading!.recordedAt}',
                          ),
                          text: TextSpan(
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                            children: [
                              TextSpan(text: _formatValue(reading!.value)),
                              TextSpan(
                                text: ' ${reading!.unit}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  static String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return 'Now';
    }

    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }

    return '${diff.inDays}d ago';
  }
}
