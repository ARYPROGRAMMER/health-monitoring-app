import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/metric_illustration.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/progress_metric_row.dart';
import '../../../core/widgets/range_toggle.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/signature_painters.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/health_models.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import 'metric_kind.dart';

class MetricDetailScreen extends StatefulWidget {
  const MetricDetailScreen({required this.kind, super.key});

  final MetricKind kind;

  /// Opens the detail screen while forwarding the existing [DashboardBloc].
  static void open(BuildContext context, MetricKind kind) {
    final bloc = context.read<DashboardBloc>();
    final profile = context.read<ProfileCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: profile),
          ],
          child: MetricDetailScreen(kind: kind),
        ),
      ),
    );
  }

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  int _range = 0; // 0 = Day, 1 = Week

  MetricKind get kind => widget.kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              final summary = state.summary;
              if (summary == null) return const LoadingView();
              return _buildContent(context, summary);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardSummaryModel summary) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final trend = kind.trend(summary);
    final values = trend.map((p) => p.value).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        _TopBar(),
        const SizedBox(height: 18),
        // Hero: big number + unit + illustration
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.display(summary),
                    style: AppTypography.hero(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kind.unit,
                    style: AppTypography.monoStyle(
                      15,
                      FontWeight.w400,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            MetricIllustration(name: kind.illustration, height: 116),
          ],
        ),
        const SizedBox(height: 22),
        _SignatureStrip(kind: kind),
        const SizedBox(height: 22),
        ..._statRows(summary, values),
        const SizedBox(height: 18),
        Center(
          child: RangeToggle(
            index: _range,
            onChanged: (i) => setState(() => _range = i),
          ),
        ),
        const SizedBox(height: 22),
        ..._secondary(context, summary, values),
        const SizedBox(height: 20),
        _TrendCard(kind: kind, points: _ranged(trend)),
        const SizedBox(height: 20),
        _Insights(summary: summary, kind: kind),
      ],
    );
  }

  List<TrendPointModel> _ranged(List<TrendPointModel> trend) {
    if (_range == 0 && trend.length > 8) {
      return trend.sublist(trend.length - 8);
    }
    return trend;
  }

  // --- Stat rows -----------------------------------------------------------

  List<Widget> _statRows(DashboardSummaryModel summary, List<double> values) {
    final rows = <(String, String)>[];
    switch (kind) {
      case MetricKind.heart:
        rows.add(('Highest Heart Rate', _max(values)));
        rows.add(('Lowest Heart Rate', _min(values)));
      case MetricKind.steps:
        rows.add(('Steps Taken Yesterday', _yesterday(summary, values)));
        rows.add(('Average Steps Count', _avg(values)));
      case MetricKind.spo2:
        rows.add(('Highest SpO₂', _max(values)));
        rows.add(('Lowest SpO₂', _min(values)));
      case MetricKind.calories:
        rows.add(('Calories Consumed', '0'));
        rows.add(('Net Calories', 'Not Available'));
    }
    return [
      for (final row in rows) ...[
        _StatRow(label: row.$1, value: row.$2),
        const SizedBox(height: 14),
      ],
    ];
  }

  // --- Secondary, metric-specific section ---------------------------------

  List<Widget> _secondary(
    BuildContext context,
    DashboardSummaryModel summary,
    List<double> values,
  ) {
    switch (kind) {
      case MetricKind.heart:
        final hrv = _hrv(values);
        return [
          ProgressMetricRow(
            icon: Icons.monitor_heart_rounded,
            label: 'Heart Rate Variability',
            progress: hrv / 120,
            trailing: values.isEmpty ? '--' : '$hrv ms',
          ),
          const SizedBox(height: 14),
          ProgressMetricRow(
            icon: Icons.self_improvement_rounded,
            label: 'Stress level',
            progress: _stressProgress(summary),
            trailing: _stressLabel(summary),
          ),
        ];
      case MetricKind.steps:
        final goal = summary.settings.dailyStepsGoal;
        final value = summary.activity?.value ?? 0;
        return [
          ProgressMetricRow(
            icon: Icons.emoji_events_rounded,
            label: "Today's Goal",
            progress: goal == 0 ? 0 : value / goal,
            trailing: '$goal',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  title: "Yesterday's Count",
                  value: _yesterday(summary, values),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _MiniCard(
                  title: 'Achievement Earned',
                  value: 'See Your Badges',
                  italic: true,
                ),
              ),
            ],
          ),
        ];
      case MetricKind.spo2:
        return [
          const ProgressMetricRow(
            icon: Icons.air_rounded,
            label: 'Air Quality',
            progress: 0,
            trailing: 'N/A',
          ),
          const SizedBox(height: 14),
          const _MiniCard(title: 'Altitude (from sea level)', value: '—'),
        ];
      case MetricKind.calories:
        return [
          GlowCard(
            color: AppTokens.of(context).elevatedCard,
            padding: const EdgeInsets.all(8),
            radius: 16,
            onTap: () => _comingSoon(context, 'Diet plans'),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose Your Diet Plan',
                    style: AppTypography.monoStyle(
                      13,
                      FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.of(context).accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Color(0xFF15161C),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what are coming soon.')));
  }

  // --- Derived helpers -----------------------------------------------------

  String _max(List<double> v) => v.isEmpty ? '--' : formatNumber(v.reduce(math.max));
  String _min(List<double> v) => v.isEmpty ? '--' : formatNumber(v.reduce(math.min));
  String _avg(List<double> v) =>
      v.isEmpty ? '--' : formatNumber(v.reduce((a, b) => a + b) / v.length);
  String _yesterday(DashboardSummaryModel s, List<double> v) {
    if (v.length >= 2) return formatNumber(v[v.length - 2]);
    if (s.activity != null) return formatNumber(s.activity!.value);
    return '--';
  }

  int _hrv(List<double> v) {
    if (v.length < 2) return 0;
    final mean = v.reduce((a, b) => a + b) / v.length;
    final variance =
        v.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / v.length;
    return (math.sqrt(variance) * 4 + 30).clamp(20, 120).round();
  }

  double _stressProgress(DashboardSummaryModel s) {
    final hr = s.heartRate?.value;
    if (hr == null) return 0;
    final max = s.settings.heartRateMax.toDouble();
    return (hr / max).clamp(0.0, 1.0);
  }

  String _stressLabel(DashboardSummaryModel s) {
    final hr = s.heartRate?.value;
    if (hr == null) return '--';
    final mid = (s.settings.heartRateMin + s.settings.heartRateMax) / 2;
    if (hr <= mid) return 'Low';
    if (hr <= s.settings.heartRateMax) return 'Moderate';
    return 'High';
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profile) => Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Text(
            'Hi ${profile.firstName}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.notifications_none_rounded, size: 22, color: tokens.accentColor),
          const Spacer(),
          ProfileAvatar(photoUrl: profile.profile?.photoUrl, size: 38),
        ],
      ),
    );
  }
}

class _SignatureStrip extends StatelessWidget {
  const _SignatureStrip({required this.kind});

  final MetricKind kind;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final painter = switch (kind) {
      MetricKind.heart => EcgPainter(
        color: tokens.glow,
        gridColor: (tokens.isDark ? Colors.white : Colors.black)
            .withValues(alpha: 0.06),
      ),
      MetricKind.steps => FootstepsPainter(
        color: tokens.accentColor,
        muted: tokens.textMuted.withValues(alpha: 0.5),
      ),
      MetricKind.spo2 => BubblesPainter(color: tokens.accentColor),
      MetricKind.calories => FlamePainter(color: tokens.accentColor),
    };
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: CustomPaint(painter: painter),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.monoStyle(14, FontWeight.w400, color: onSurface)),
        Text(value, style: AppTypography.monoStyle(14, FontWeight.w700, color: onSurface)),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.value, this.italic = false});

  final String title;
  final String value;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tokens.accentColor.withValues(alpha: 0.16),
          tokens.card,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.monoStyle(11, FontWeight.w400, color: tokens.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.monoStyle(
              italic ? 12 : 17,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ).copyWith(fontStyle: italic ? FontStyle.italic : FontStyle.normal),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.kind, required this.points});

  final MetricKind kind;
  final List<TrendPointModel> points;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Trend'),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No ${kind.unit} readings synced yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    margin: EdgeInsets.zero,
                    primaryXAxis: DateTimeAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                      dateFormat: DateFormat(points.length > 10 ? 'ha' : 'MMM d'),
                      labelStyle: AppTypography.monoStyle(
                        10,
                        FontWeight.w400,
                        color: tokens.textMuted,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                      majorGridLines: MajorGridLines(
                        width: 0.5,
                        color: tokens.track,
                      ),
                      labelStyle: AppTypography.monoStyle(
                        10,
                        FontWeight.w400,
                        color: tokens.textMuted,
                      ),
                    ),
                    series: <CartesianSeries<TrendPointModel, DateTime>>[
                      SplineAreaSeries<TrendPointModel, DateTime>(
                        dataSource: points,
                        xValueMapper: (p, _) => p.recordedAt,
                        yValueMapper: (p, _) => p.value,
                        borderColor: tokens.accentColor,
                        borderWidth: 2.6,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tokens.accentColor.withValues(alpha: 0.28),
                            tokens.accentColor.withValues(alpha: 0.02),
                          ],
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

class _Insights extends StatelessWidget {
  const _Insights({required this.summary, required this.kind});

  final DashboardSummaryModel summary;
  final MetricKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = summary.insights.map((i) => i.message).toList();
    if (messages.isEmpty) {
      messages.add(_fallback(kind));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final message in messages.take(2)) ...[
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  String _fallback(MetricKind kind) => switch (kind) {
    MetricKind.heart =>
      'Keep your heart rate within your personal range to stay in the green.',
    MetricKind.steps =>
      'Consistent daily steps build long-term cardiovascular health.',
    MetricKind.spo2 =>
      'Healthy SpO₂ usually sits between 95% and 100% at rest.',
    MetricKind.calories =>
      'Balance active calories with nutrition for steady energy.',
  };
}
