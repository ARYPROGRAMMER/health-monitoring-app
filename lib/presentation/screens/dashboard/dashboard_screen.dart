import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health_models.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/add_reading_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return state.when(
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await ref.read(dashboardControllerProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            if (summary?.isOffline == true)
              _OfflineBanner(message: summary?.errorMessage),
            _DashboardHero(summary: summary),
            const SizedBox(height: 18),
            if (summary == null || !summary.hasVitals)
              EmptyState(
                icon: Icons.sensors_rounded,
                title: 'No health readings yet',
                message:
                    'Add your first reading to populate vitals, alerts, charts, insights, and offline cache.',
                action: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AddReadingSheet.show(context);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add reading'),
                ),
              )
            else
              _MetricGrid(summary: summary),
            const SizedBox(height: 18),
            if (summary != null && summary.hasVitals) ...[
              _TargetSection(summary: summary),
              const SizedBox(height: 18),
              _TimelineSection(summary: summary),
              const SizedBox(height: 18),
            ],
            _InsightSection(summary: summary),
            const SizedBox(height: 18),
            _AlertPreview(summary: summary),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await ref.read(dashboardControllerProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Backend unavailable',
              message: error.toString(),
              action: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(dashboardControllerProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.summary});

  final DashboardSummaryModel? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertCount = summary?.activeAlerts.length ?? 0;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Health Command Center',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _PulseBadge(alertCount: alertCount),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary?.generatedAt.millisecondsSinceEpoch == 0
                ? 'Waiting for the first backend refresh.'
                : 'Last refreshed ${_formatRefreshTime(summary!.generatedAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRefreshTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    }

    if (diff.inHours < 1) {
      return '${diff.inMinutes} minutes ago';
    }

    return '${diff.inHours} hours ago';
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.96,
      children: [
        MetricCard(
          title: 'Heart Rate',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFB7185),
          reading: summary.heartRate,
        ),
        MetricCard(
          title: 'SpO2',
          icon: Icons.air_rounded,
          color: const Color(0xFF2DD4BF),
          reading: summary.spo2,
        ),
        MetricCard(
          title: 'Sleep',
          icon: Icons.nightlight_round,
          color: const Color(0xFF60A5FA),
          reading: summary.sleep,
        ),
        MetricCard(
          title: 'Activity',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFFF59E0B),
          reading: summary.activity,
        ),
      ],
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.summary});

  final DashboardSummaryModel? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = summary?.insights ?? [];

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized Insights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (insights.isEmpty)
            Text(
              'Insights will appear when enough vitals are available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...insights.map((insight) => _InsightTile(insight: insight)),
        ],
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = _TargetItem.fromSummary(summary);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Against Goals',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...targets.map((target) => _TargetRow(target: target)),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.target});

  final _TargetItem target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: target.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(target.icon, color: target.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.caption,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(target.progress * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: target.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: target.progress),
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: target.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(target.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _TimelineEntry.fromSummary(summary);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Timeline',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Text(
              'Recent readings will appear here after sync.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.map((entry) => _TimelineRow(entry: entry)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: entry.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(entry.recordedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatValue(entry.value)} ${entry.unit}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final HealthInsightModel insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.tone) {
      'critical' => const Color(0xFFEF4444),
      'warning' => const Color(0xFFF59E0B),
      _ => const Color(0xFF0D9488),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${insight.title}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: insight.message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertPreview extends StatelessWidget {
  const _AlertPreview({required this.summary});

  final DashboardSummaryModel? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = summary?.activeAlerts ?? [];

    return GlassPanel(
      child: Row(
        children: [
          Icon(
            alerts.isEmpty
                ? Icons.shield_rounded
                : Icons.notification_important_rounded,
            color: alerts.isEmpty
                ? theme.colorScheme.primary
                : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alerts.isEmpty
                  ? 'No active health alerts.'
                  : '${alerts.length} active alert${alerts.length == 1 ? '' : 's'} need review.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(child: Text(message ?? 'Showing cached data.')),
          ],
        ),
      ),
    );
  }
}

class _PulseBadge extends StatelessWidget {
  const _PulseBadge({required this.alertCount});

  final int alertCount;

  @override
  Widget build(BuildContext context) {
    final color = alertCount == 0
        ? const Color(0xFF0D9488)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        alertCount == 0 ? 'Stable' : '$alertCount alerts',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TargetItem {
  const _TargetItem({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final double progress;

  static List<_TargetItem> fromSummary(DashboardSummaryModel summary) {
    final settings = summary.settings;
    final items = <_TargetItem>[];

    if (summary.heartRate != null) {
      final value = summary.heartRate!.value;
      final inRange =
          value >= settings.heartRateMin && value <= settings.heartRateMax;
      items.add(
        _TargetItem(
          label: 'Heart range',
          caption:
              '${_formatValue(value)} bpm inside ${settings.heartRateMin}-${settings.heartRateMax} bpm',
          icon: Icons.favorite_rounded,
          color: inRange ? const Color(0xFF0D9488) : const Color(0xFFEF4444),
          progress: inRange ? 1 : 0.42,
        ),
      );
    }

    if (summary.spo2 != null) {
      final value = summary.spo2!.value;
      items.add(
        _TargetItem(
          label: 'Oxygen floor',
          caption:
              '${_formatValue(value)}% against ${_formatValue(settings.spo2Min)}% minimum',
          icon: Icons.air_rounded,
          color: const Color(0xFF2DD4BF),
          progress: (value / settings.spo2Min).clamp(0, 1).toDouble(),
        ),
      );
    }

    if (summary.sleep != null) {
      final value = summary.sleep!.value;
      items.add(
        _TargetItem(
          label: 'Sleep target',
          caption:
              '${_formatValue(value)} h of ${_formatValue(settings.sleepTargetHours)} h',
          icon: Icons.nightlight_round,
          color: const Color(0xFF60A5FA),
          progress: (value / settings.sleepTargetHours).clamp(0, 1).toDouble(),
        ),
      );
    }

    if (summary.activity != null) {
      final value = summary.activity!.value;
      items.add(
        _TargetItem(
          label: 'Activity goal',
          caption:
              '${_formatValue(value)} steps of ${settings.dailyStepsGoal} steps',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFFF59E0B),
          progress: (value / settings.dailyStepsGoal).clamp(0, 1).toDouble(),
        ),
      );
    }

    return items;
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.label,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final IconData icon;
  final Color color;

  static List<_TimelineEntry> fromSummary(DashboardSummaryModel summary) {
    final entries = <_TimelineEntry>[
      ...summary.heartRateTrend.map(
        (point) => _TimelineEntry(
          label: 'Heart Rate',
          value: point.value,
          unit: point.unit,
          recordedAt: point.recordedAt,
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFB7185),
        ),
      ),
      ...summary.spo2Trend.map(
        (point) => _TimelineEntry(
          label: 'SpO2',
          value: point.value,
          unit: point.unit,
          recordedAt: point.recordedAt,
          icon: Icons.air_rounded,
          color: const Color(0xFF2DD4BF),
        ),
      ),
      ...summary.sleepTrend.map(
        (point) => _TimelineEntry(
          label: 'Sleep',
          value: point.value,
          unit: point.unit,
          recordedAt: point.recordedAt,
          icon: Icons.nightlight_round,
          color: const Color(0xFF60A5FA),
        ),
      ),
      ...summary.activityTrend.map(
        (point) => _TimelineEntry(
          label: 'Activity',
          value: point.value,
          unit: point.unit,
          recordedAt: point.recordedAt,
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ),
    ];

    entries.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return entries.take(6).toList();
  }
}

String _formatValue(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) {
    return 'Just now';
  }

  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }

  if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  }

  return '${diff.inDays}d ago';
}
