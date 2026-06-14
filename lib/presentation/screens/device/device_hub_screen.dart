import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/device_models.dart';
import '../../../data/models/metric_catalog.dart';
import '../../../data/repositories/health_repository.dart';
import '../../blocs/common/load_cubit.dart';
import '../../blocs/device_dashboard/device_dashboard_bloc.dart';
import '../metrics/metric_detail_screen.dart';

class DeviceHubScreen extends StatelessWidget {
  const DeviceHubScreen({super.key});

  static void open(BuildContext context, String deviceId) {
    final repo = context.read<HealthRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => DeviceDashboardBloc(
                repository: repo,
                deviceId: deviceId,
              )..add(const DashboardStarted()),
            ),
            BlocProvider(
              create: (_) => LoadCubit<DeviceInfo>(() => repo.info(deviceId))
                ..load(),
            ),
            BlocProvider(
              create: (_) =>
                  LoadCubit<LocationTrack>(() => repo.location(deviceId))
                    ..load(),
            ),
            BlocProvider(
              create: (_) => LoadCubit<SosData>(() => repo.sos(deviceId))
                ..load(),
            ),
            BlocProvider(
              create: (_) => LoadCubit<EcgData>(() => repo.ecg(deviceId))
                ..load(),
            ),
          ],
          child: const DeviceHubScreen(),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    HapticFeedback.lightImpact();
    await context.read<DeviceDashboardBloc>().refreshAndWait();
    if (!context.mounted) return;
    await Future.wait([
      context.read<LoadCubit<DeviceInfo>>().load(silent: true),
      context.read<LoadCubit<LocationTrack>>().load(silent: true),
      context.read<LoadCubit<SosData>>().load(silent: true),
      context.read<LoadCubit<EcgData>>().load(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        glowAlignment: Alignment.topCenter,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<DeviceDashboardBloc, DeviceDashboardState>(
            builder: (context, state) {
              if (state.status == DashboardStatus.loading &&
                  state.summary == null) {
                return const LoadingView();
              }
              if (state.status == DashboardStatus.failure &&
                  state.summary == null) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    const _TopBar(title: 'Device'),
                    const SizedBox(height: 24),
                    ErrorView(
                      message:
                          state.errorMessage ?? 'Unable to load device data.',
                      onRetry: () => context
                          .read<DeviceDashboardBloc>()
                          .add(const DashboardRefreshed()),
                    ),
                  ],
                );
              }
              if (state.summary == null) {
                return const LoadingView();
              }
              return RefreshIndicator(
                color: AppTokens.of(context).accentColor,
                onRefresh: () => _refresh(context),
                child: _DeviceDashboardContent(state: state),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DeviceDashboardContent extends StatelessWidget {
  const _DeviceDashboardContent({required this.state});

  final DeviceDashboardState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        _TopBar(title: summary.displayName),
        const SizedBox(height: 16),
        _HeroCard(state: state),
        if (state.isOffline) ...[
          const SizedBox(height: 12),
          _OfflineBanner(message: state.errorMessage),
        ],
        const SizedBox(height: 20),
        const SectionHeader('Vitals'),
        const SizedBox(height: 12),
        _MetricGrid(specs: MetricSpec.vitals, state: state, columns: 2),
        const SizedBox(height: 20),
        const SectionHeader('Activity'),
        const SizedBox(height: 12),
        _ActivityCard(activity: state.activity, latest: state.latest),
        const SizedBox(height: 20),
        const SectionHeader('Wellness'),
        const SizedBox(height: 12),
        _MetricGrid(
          specs: const [
            MetricSpec.hrv,
            MetricSpec.stress,
            MetricSpec.bloodSugar,
            MetricSpec.bmi,
          ],
          state: state,
          columns: 2,
        ),
        const SizedBox(height: 12),
        _SleepCard(wellness: state.wellness),
        const SizedBox(height: 20),
        const SectionHeader('Safety and Diagnostics'),
        const SizedBox(height: 12),
        const _SosCard(),
        const SizedBox(height: 12),
        const _LocationCard(),
        const SizedBox(height: 12),
        const _EcgCard(),
        const SizedBox(height: 20),
        const SectionHeader('Device Info'),
        const SizedBox(height: 12),
        const _DeviceInfoCard(),
      ],
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final DeviceDashboardState state;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final summary = state.summary!;
    final latest = summary.latest;
    final battery = latest.battery;
    final signal = latest.rssi;
    return GlowCard(
      glow: state.isLive,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.watch_rounded,
                  color: tokens.accentColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.deviceId,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoStyle(
                        12,
                        FontWeight.w700,
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          icon: state.isLive
                              ? Icons.bolt_rounded
                              : Icons.sync_rounded,
                          label: state.isLive ? 'Live' : 'Polling',
                          color: state.isLive ? tokens.success : tokens.warning,
                        ),
                        _Chip(
                          icon: Icons.circle,
                          label: summary.status,
                          color: summary.status.toLowerCase() == 'online'
                              ? tokens.success
                              : tokens.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Battery',
                  value: battery == null ? '--' : formatNumber(battery),
                  unit: '%',
                  icon: latest.charging
                      ? Icons.battery_charging_full_rounded
                      : Icons.battery_5_bar_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Signal',
                  value: signal == null ? '--' : formatNumber(signal),
                  unit: 'dBm',
                  icon: Icons.signal_cellular_alt_rounded,
                ),
              ),
            ],
          ),
          if (summary.lastSeen.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Last seen ${summary.lastSeen}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.elevatedCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: tokens.accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.monoStyle(
                    11,
                    FontWeight.w400,
                    color: tokens.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$value $unit',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoStyle(
                    15,
                    FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.specs,
    required this.state,
    required this.columns,
  });

  final List<MetricSpec> specs;
  final DeviceDashboardState state;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i += columns) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (i + j < specs.length)
                Expanded(
                  child: _MetricCard(
                    spec: specs[i + j],
                    latest: state.latest,
                    spark: _sparkFor(specs[i + j], state),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              if (j < columns - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows.take(rows.length - 1).toList());
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.spec, required this.latest, this.spark = const []});

  final MetricSpec spec;
  final LatestSnapshot? latest;
  final List<double> spark;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final raw = _rawValue(spec, latest);
    final display = _display(spec, latest);
    final outOfRange = raw != null && spec.isOutOfRange(raw);
    return GlowCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      borderColor: outOfRange
          ? tokens.danger.withValues(alpha: 0.45)
          : spec.color.withValues(alpha: 0.28),
      onTap: () => MetricDetailScreen.open(
        context,
        context.read<DeviceDashboardBloc>().state.deviceId,
        spec,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, color: spec.color, size: 22),
              const Spacer(),
              if (outOfRange)
                Icon(Icons.warning_amber_rounded, color: tokens.danger, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          _LiveValue(
            value: display,
            style: AppTypography.monoStyle(
              22,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spec.shortTitle,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              11,
              FontWeight.w400,
              color: tokens.textMuted,
            ),
          ),
          if (spark.length > 1) ...[
            const SizedBox(height: 10),
            Sparkline(values: spark, color: spec.color, height: 28),
          ],
        ],
      ),
    );
  }
}

/// Cross-fades when its [value] changes so realtime ticks feel alive.
class _LiveValue extends StatelessWidget {
  const _LiveValue({required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          axis: Axis.horizontal,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: Text(
        value,
        key: ValueKey(value),
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

List<double> _sparkFor(MetricSpec spec, DeviceDashboardState state) {
  if (spec.key == 'bloodPressure') {
    return state.vitals?.bloodPressure.series.map((p) => p.systolic).toList() ??
        const [];
  }
  final List<TimeValue>? s = switch (spec.key) {
    'heartRate' => state.vitals?.heartRate.series,
    'bloodOxygen' => state.vitals?.bloodOxygen.series,
    'bodyTemp' => state.vitals?.bodyTemp.core.series,
    'steps' => state.activity?.steps.series,
    'distance' => state.activity?.distance.series,
    'calories' => state.activity?.calories.series,
    'hrv' => state.wellness?.heartHealth.series,
    'stress' => state.wellness?.pressure.series,
    _ => null,
  };
  return s?.map((t) => t.value).toList() ?? const [];
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.latest});

  final Activity? activity;
  final LatestSnapshot? latest;

  @override
  Widget build(BuildContext context) {
    final steps = activity?.steps.total ?? latest?.steps ?? 0;
    final distance = activity?.distance.total ?? latest?.distance ?? 0;
    final calories = activity?.calories.total ?? latest?.calories ?? 0;
    return Row(
      children: [
        Expanded(
          child: _ActionMetric(
            icon: Icons.directions_walk_rounded,
            label: 'Steps',
            value: formatNumber(steps),
            unit: '',
            spec: MetricSpec.steps,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionMetric(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: formatNumber(distance),
            unit: 'm',
            spec: MetricSpec.distance,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionMetric(
            icon: Icons.local_fire_department_rounded,
            label: 'Calories',
            value: formatNumber(calories),
            unit: 'kcal',
            spec: MetricSpec.calories,
          ),
        ),
      ],
    );
  }
}

class _ActionMetric extends StatelessWidget {
  const _ActionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.spec,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.all(13),
      radius: 18,
      onTap: () => MetricDetailScreen.open(
        context,
        context.read<DeviceDashboardBloc>().state.deviceId,
        spec,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.accentColor, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              18,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit.isEmpty ? label : '$label $unit',
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

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.wellness});

  final Wellness? wellness;

  @override
  Widget build(BuildContext context) {
    final sleep = wellness?.sleep;
    final tokens = AppTokens.of(context);
    return GlowCard(
      child: Row(
        children: [
          Icon(Icons.bedtime_rounded, color: tokens.accentColor, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sleep == null || !sleep.hasData
                      ? '-- h'
                      : '${sleep.totalHours.toStringAsFixed(1)} h',
                  style: AppTypography.monoStyle(
                    22,
                    FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sleep == null
                      ? 'Sleep'
                      : 'Deep ${sleep.deepMinutes}m, light ${sleep.lightMinutes}m, score ${formatNumber(sleep.sleepScore)}',
                  overflow: TextOverflow.ellipsis,
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

class _SosCard extends StatelessWidget {
  const _SosCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadCubit<SosData>, Async<SosData>>(
      builder: (context, state) {
        final sos = state.data;
        final hasDetail = sos != null && !sos.isEmpty;
        return GlowCard(
          onTap: hasDetail ? () => _showSosSheet(context, sos) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                icon: Icons.sos_rounded,
                title: 'SOS and Calls',
                loading: state.isLoading,
                trailing: hasDetail
                    ? const Icon(Icons.chevron_right_rounded, size: 22)
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CountTile(
                      label: 'SOS',
                      value: sos?.sosEvents.length ?? 0,
                      color: AppTokens.of(context).danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountTile(
                      label: 'Falls',
                      value: sos?.fallAlarms.length ?? 0,
                      color: AppTokens.of(context).warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountTile(
                      label: 'Calls',
                      value: sos?.callLogs.length ?? 0,
                      color: AppTokens.of(context).accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadCubit<LocationTrack>, Async<LocationTrack>>(
      builder: (context, state) {
        final track = state.data;
        return GlowCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                icon: Icons.location_on_rounded,
                title: 'Location',
                loading: state.isLoading,
              ),
              const SizedBox(height: 12),
              if (track == null || !track.hasData)
                Text(
                  state.error ?? 'No location points for the latest window.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                _MiniMap(track: track),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.track});

  final LocationTrack track;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final points = track.tracks.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = points.isNotEmpty
        ? points.last
        : LatLng(track.lastLat ?? 0, track.lastLng ?? 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 190,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'health_monitoring_app',
            ),
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: tokens.accentColor,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.location_pin,
                    color: tokens.danger,
                    size: 38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EcgCard extends StatelessWidget {
  const _EcgCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadCubit<EcgData>, Async<EcgData>>(
      builder: (context, state) {
        final record = state.data?.records.isNotEmpty == true
            ? state.data!.records.last
            : null;
        return GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                icon: Icons.monitor_heart_rounded,
                title: 'ECG',
                loading: state.isLoading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 86,
                width: double.infinity,
                child: record == null
                    ? Center(
                        child: Text(
                          state.error ?? 'No ECG record available.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : CustomPaint(
                        painter: _EcgWavePainter(
                          wave: record.wave,
                          color: AppTokens.of(context).danger,
                        ),
                      ),
              ),
              if (state.data?.aiResult.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  state.data!.aiResult,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadCubit<DeviceInfo>, Async<DeviceInfo>>(
      builder: (context, state) {
        final info = state.data;
        if (info == null) {
          return GlowCard(
            child: _CardTitle(
              icon: Icons.info_outline_rounded,
              title: state.error ?? 'Loading device info',
              loading: state.isLoading,
            ),
          );
        }
        return GlowCard(
          child: Column(
            children: [
              _InfoRow(label: 'Model', value: info.model),
              _InfoRow(label: 'Firmware', value: info.firmwareVersion),
              _InfoRow(label: 'Phone', value: info.phone),
              _InfoRow(label: 'MAC', value: info.macAddress),
              _InfoRow(label: 'Network', value: info.networkType),
              _InfoRow(label: 'Operator', value: info.networkOperator),
              _InfoRow(label: 'SIM', value: info.simIccid),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoStyle(
                12,
                FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.loading,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final bool loading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Row(
      children: [
        Icon(icon, color: tokens.accentColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (loading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.accentColor,
            ),
          )
        else if (trailing != null)
          IconTheme(
            data: IconThemeData(color: tokens.textMuted),
            child: trailing!,
          ),
      ],
    );
  }
}

void _showSosSheet(BuildContext context, SosData sos) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SosSheet(sos: sos),
  );
}

class _SosSheet extends StatelessWidget {
  const _SosSheet({required this.sos});

  final SosData sos;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final theme = Theme.of(context);
    final events = [...sos.sosEvents, ...sos.fallAlarms, ...sos.sedentaryAlarms];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: tokens.isDark ? const Color(0xFF111315) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: tokens.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.sos_rounded, color: tokens.danger),
                const SizedBox(width: 10),
                Text(
                  'SOS, Falls & Calls',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Text('No SOS or fall events recorded.',
                  style: theme.textTheme.bodyMedium)
            else
              for (final e in events) ...[
                _SosEventRow(alarm: e),
                const SizedBox(height: 10),
              ],
            if (sos.callLogs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionHeader('Call log'),
              const SizedBox(height: 10),
              for (final call in sos.callLogs) ...[
                _CallRow(call: call),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SosEventRow extends StatelessWidget {
  const _SosEventRow({required this.alarm});

  final AlarmRow alarm;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final color = alarm.isSos ? tokens.danger : tokens.warning;
    final point = alarm.latLng;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            alarm.isSos ? Icons.sos_rounded : Icons.personal_injury_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.type.isEmpty ? 'Event' : alarm.type.toUpperCase(),
                  style: AppTypography.monoStyle(13, FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  alarm.time,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          if (point != null)
            IconButton(
              tooltip: 'Open in maps',
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${point.$1},${point.$2}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: Icon(Icons.map_rounded, color: tokens.accentColor),
            ),
        ],
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.call});

  final CallLog call;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.elevatedCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.call_rounded, color: tokens.accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.number.isEmpty ? 'Unknown' : call.number,
                  style: AppTypography.monoStyle(
                    14,
                    FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call.startTime,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          if (call.number.isNotEmpty)
            IconButton(
              tooltip: 'Call',
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: call.number)),
              icon: Icon(Icons.phone_forwarded_rounded, color: tokens.success),
            ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: AppTypography.monoStyle(
              21,
              FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              10,
              FontWeight.w400,
              color: AppTokens.of(context).textMuted,
            ),
          ),
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label.isEmpty ? 'unknown' : label,
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      borderColor: tokens.warning.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: tokens.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'Showing the last loaded snapshot.',
              style: AppTypography.monoStyle(
                12,
                FontWeight.w400,
                color: tokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgWavePainter extends CustomPainter {
  _EcgWavePainter({required this.wave, required this.color});

  final List<double> wave;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (wave.length < 2) return;
    final min = wave.reduce((a, b) => a < b ? a : b);
    final max = wave.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.001 ? 1 : max - min;
    final path = ui.Path();
    for (var i = 0; i < wave.length; i++) {
      final x = i / (wave.length - 1) * size.width;
      final y = size.height - ((wave[i] - min) / span * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgWavePainter oldDelegate) =>
      oldDelegate.wave != wave || oldDelegate.color != color;
}

double? _rawValue(MetricSpec spec, LatestSnapshot? latest) {
  if (latest == null) return null;
  return switch (spec.key) {
    'heartRate' => latest.heartRate,
    'bloodOxygen' => latest.spo2,
    'bodyTemp' => latest.bodyTemp,
    'bloodPressure' => latest.bpSystolic,
    'steps' => latest.steps,
    'distance' => latest.distance,
    'calories' => latest.calories,
    'hrv' => latest.hrvSdnn,
    'stress' => latest.stress,
    'respiration' => latest.respiration,
    'bloodSugar' => latest.bloodSugar,
    'bmi' => _number(latest.raw['bmi']),
    _ => null,
  };
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _display(MetricSpec spec, LatestSnapshot? latest) {
  if (spec.key == 'bloodPressure') {
    final sys = latest?.bpSystolic;
    final dia = latest?.bpDiastolic;
    if (sys == null || dia == null) return '--';
    return '${formatNumber(sys)}/${formatNumber(dia)}';
  }
  final value = _rawValue(spec, latest);
  if (value == null || (!spec.allowZero && value == 0)) return '--';
  final formatted = spec.decimals == 0
      ? formatNumber(value)
      : value.toStringAsFixed(spec.decimals);
  return spec.unit.isEmpty ? formatted : '$formatted ${spec.unit}';
}
