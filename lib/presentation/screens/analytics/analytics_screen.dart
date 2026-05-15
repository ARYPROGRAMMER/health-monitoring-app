import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../data/models/health_models.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return state.when(
      data: (summary) {
        if (summary == null || !summary.hasVitals) {
          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await ref.read(dashboardControllerProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: const [
                EmptyState(
                  icon: Icons.query_stats_rounded,
                  title: 'No trends available',
                  message:
                      'Charts appear after heart rate, SpO2, sleep, or activity readings are synced.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await ref.read(dashboardControllerProvider.notifier).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _TrendChart(
                title: 'Heart rate trend',
                unit: 'bpm',
                color: const Color(0xFFFB7185),
                points: summary.heartRateTrend,
              ),
              const SizedBox(height: 16),
              _TrendChart(
                title: 'SpO2 trend',
                unit: '%',
                color: const Color(0xFF2DD4BF),
                points: summary.spo2Trend,
              ),
              const SizedBox(height: 16),
              _TrendChart(
                title: 'Sleep pattern',
                unit: 'hours',
                color: const Color(0xFF60A5FA),
                points: summary.sleepTrend,
              ),
              const SizedBox(height: 16),
              _TrendChart(
                title: 'Activity trend',
                unit: 'steps',
                color: const Color(0xFFF59E0B),
                points: summary.activityTrend,
              ),
            ],
          ),
        );
      },
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
              icon: Icons.error_outline_rounded,
              title: 'Unable to load analytics',
              message: error.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.unit,
    required this.color,
    required this.points,
  });

  final String title;
  final String unit;
  final Color color;
  final List<TrendPointModel> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No $unit readings synced yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      dateFormat: DateFormat(
                        points.length > 10 ? 'ha' : 'MMM d',
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: [
                      SplineAreaSeries<TrendPointModel, DateTime>(
                        dataSource: points,
                        xValueMapper: (point, index) => point.recordedAt,
                        yValueMapper: (point, index) => point.value,
                        borderColor: color,
                        borderWidth: 3,
                        color: color.withValues(alpha: 0.16),
                        markerSettings: MarkerSettings(
                          isVisible: points.length <= 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
