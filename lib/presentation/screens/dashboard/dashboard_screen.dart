import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health_models.dart';
import '../../controllers/dashboard_controller.dart';
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
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).refresh(),
        child: ListView(
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
                    'Connect a wearable or sync readings through the backend to populate vitals, alerts, charts, and insights.',
                action: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              )
            else
              _MetricGrid(summary: summary),
            const SizedBox(height: 18),
            _InsightSection(summary: summary),
            const SizedBox(height: 18),
            _AlertPreview(summary: summary),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Backend unavailable',
            message: error.toString(),
            action: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        ],
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
