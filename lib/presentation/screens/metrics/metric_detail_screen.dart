import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/range_toggle.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/device_models.dart';
import '../../../data/models/metric_catalog.dart';
import '../../../data/repositories/health_repository.dart';
import '../../blocs/metric_detail/metric_detail_bloc.dart';

class MetricDetailScreen extends StatelessWidget {
  const MetricDetailScreen({required this.spec, super.key});

  final MetricSpec spec;

  static void open(BuildContext context, String deviceId, MetricSpec spec) {
    final repo = context.read<HealthRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => MetricDetailBloc(
            repository: repo,
            deviceId: deviceId,
            spec: spec,
          )..add(const MetricStarted()),
          child: MetricDetailScreen(spec: spec),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    HapticFeedback.lightImpact();
    final bloc = context.read<MetricDetailBloc>();
    bloc.add(const MetricRefreshed());
    await bloc.stream
        .firstWhere((s) => s.status != MetricStatus.loading)
        .timeout(const Duration(seconds: 8), onTimeout: () {
      return bloc.state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<MetricDetailBloc, MetricDetailState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: spec.color,
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    _TopBar(title: spec.title),
                    const SizedBox(height: 18),
                    if (state.status == MetricStatus.loading &&
                        state.series == null &&
                        state.bloodPressure == null)
                      const SizedBox(height: 420, child: LoadingView())
                    else if (state.status == MetricStatus.failure)
                      ErrorView(
                        message: state.errorMessage ?? 'Unable to load metric.',
                        onRetry: () => context
                            .read<MetricDetailBloc>()
                            .add(const MetricRefreshed()),
                      )
                    else ...[
                      _Hero(spec: spec, state: state),
                      const SizedBox(height: 18),
                      _RangeChooser(state: state),
                      const SizedBox(height: 18),
                      _Stats(spec: spec, state: state),
                      const SizedBox(height: 20),
                      const SectionHeader('Series'),
                      const SizedBox(height: 12),
                      _Chart(spec: spec, state: state),
                      const SizedBox(height: 20),
                      _Warnings(spec: spec, state: state),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.spec, required this.state});

  final MetricSpec spec;
  final MetricDetailState state;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final value = _heroValue(spec, state);
    return GlowCard(
      glow: state.isLive,
      borderColor: spec.color.withValues(alpha: 0.42),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(spec.icon, color: spec.color, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (state.isLive)
                      _Chip(
                        icon: Icons.bolt_rounded,
                        label: 'Live',
                        color: tokens.success,
                      ),
                    _Chip(
                      icon: Icons.timeline_rounded,
                      label: state.range.label,
                      color: spec.color,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoStyle(
                    32,
                    FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  spec.unit.isEmpty ? spec.title : spec.unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
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

class _RangeChooser extends StatelessWidget {
  const _RangeChooser({required this.state});

  final MetricDetailState state;

  @override
  Widget build(BuildContext context) {
    final values = MetricRange.values;
    return Center(
      child: RangeToggle(
        index: values.indexOf(state.range),
        labels: values.map((range) => range.label).toList(),
        onChanged: (index) => context
            .read<MetricDetailBloc>()
            .add(MetricRangeChanged(values[index])),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.spec, required this.state});

  final MetricSpec spec;
  final MetricDetailState state;

  @override
  Widget build(BuildContext context) {
    final items = _statItems(spec, state);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _StatTile(label: items[i].$1, value: items[i].$2)),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.all(13),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              18,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              10,
              FontWeight.w400,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.spec, required this.state});

  final MetricSpec spec;
  final MetricDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.bloodPressure != null) {
      return _BloodPressureChart(data: state.bloodPressure!, color: spec.color);
    }
    final series = state.series;
    if (series == null || series.series.isEmpty) {
      return const EmptyView(
        icon: Icons.timeline_rounded,
        title: 'No points',
        message: 'The backend returned no series points for this range.',
      );
    }
    return _MetricSeriesChart(
      series: series,
      skinSeries: state.skinSeries,
      color: spec.color,
    );
  }
}

class _MetricSeriesChart extends StatelessWidget {
  const _MetricSeriesChart({
    required this.series,
    required this.skinSeries,
    required this.color,
  });

  final MetricSeries series;
  final List<TimeValue> skinSeries;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: SizedBox(
        height: 240,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            labelStyle: AppTypography.monoStyle(
              10,
              FontWeight.w400,
              color: tokens.textMuted,
            ),
          ),
          primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            majorGridLines: MajorGridLines(width: 0.5, color: tokens.track),
            labelStyle: AppTypography.monoStyle(
              10,
              FontWeight.w400,
              color: tokens.textMuted,
            ),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CartesianSeries<TimeValue, int>>[
            SplineAreaSeries<TimeValue, int>(
              dataSource: series.series,
              xValueMapper: (_, index) => index,
              yValueMapper: (point, _) => point.value,
              name: series.unit.isEmpty ? 'Value' : series.unit,
              borderColor: color,
              borderWidth: 2.6,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
            if (skinSeries.isNotEmpty)
              LineSeries<TimeValue, int>(
                dataSource: skinSeries,
                xValueMapper: (_, index) => index,
                yValueMapper: (point, _) => point.value,
                name: 'Skin',
                color: tokens.warning,
                width: 2,
              ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureChart extends StatelessWidget {
  const _BloodPressureChart({required this.data, required this.color});

  final BloodPressureSeries data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.series.isEmpty) {
      return const EmptyView(
        icon: Icons.monitor_heart_rounded,
        title: 'No blood pressure points',
        message: 'The backend returned no blood pressure points for this range.',
      );
    }
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: SizedBox(
        height: 240,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
          ),
          primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            majorGridLines: MajorGridLines(width: 0.5, color: tokens.track),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          legend: const Legend(isVisible: true),
          series: <CartesianSeries<BpPoint, int>>[
            LineSeries<BpPoint, int>(
              dataSource: data.series,
              xValueMapper: (_, index) => index,
              yValueMapper: (point, _) => point.systolic,
              name: 'Systolic',
              color: color,
              width: 2.5,
            ),
            LineSeries<BpPoint, int>(
              dataSource: data.series,
              xValueMapper: (_, index) => index,
              yValueMapper: (point, _) => point.diastolic,
              name: 'Diastolic',
              color: tokens.accentColor,
              width: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.spec, required this.state});

  final MetricSpec spec;
  final MetricDetailState state;

  @override
  Widget build(BuildContext context) {
    final warnings = state.series?.warningRecords ??
        state.bloodPressure?.warningRecords ??
        const <WarningRecord>[];
    if (warnings.isEmpty && spec.normalLow == null && spec.normalHigh == null) {
      return const SizedBox.shrink();
    }
    final tokens = AppTokens.of(context);
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Signals'),
          const SizedBox(height: 10),
          if (spec.normalLow != null || spec.normalHigh != null)
            Text(
              'Normal band ${spec.normalLow?.toStringAsFixed(0) ?? '-'} to ${spec.normalHigh?.toStringAsFixed(0) ?? '-'} ${spec.unit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final warning in warnings.take(4)) ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: tokens.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${warning.time}  ${warning.value}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.monoStyle(
              10,
              FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _heroValue(MetricSpec spec, MetricDetailState state) {
  if (state.bloodPressure != null) {
    final point = state.bloodPressure!.latest;
    if (point == null) return '--';
    return '${formatNumber(point.systolic)}/${formatNumber(point.diastolic)}';
  }
  final value = state.liveValue ?? state.series?.latest;
  if (value == null || (!spec.allowZero && value == 0)) return '--';
  final formatted = spec.decimals == 0
      ? formatNumber(value)
      : value.toStringAsFixed(spec.decimals);
  return spec.unit.isEmpty ? formatted : '$formatted ${spec.unit}';
}

List<(String, String)> _statItems(MetricSpec spec, MetricDetailState state) {
  if (state.bloodPressure != null) {
    final bp = state.bloodPressure!;
    return [
      ('SYS avg', formatNumber(bp.avgSystolic)),
      ('DIA avg', formatNumber(bp.avgDiastolic)),
      ('Points', bp.series.length.toString()),
    ];
  }
  final s = state.series;
  if (s == null) {
    return const [('Avg', '--'), ('Max', '--'), ('Points', '--')];
  }
  String f(double value) =>
      spec.decimals == 0 ? formatNumber(value) : value.toStringAsFixed(spec.decimals);
  return [
    ('Avg', f(s.average)),
    ('Max', f(s.max)),
    ('Points', s.count.toString()),
  ];
}
