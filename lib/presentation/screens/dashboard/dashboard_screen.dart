import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/device_models.dart';
import '../../blocs/devices/devices_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../device/device_hub_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.onShowAlerts, super.key});

  final VoidCallback onShowAlerts;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) {
        if (state.status == DevicesStatus.loading && state.devices.isEmpty) {
          return const LoadingView();
        }

        if (state.status == DevicesStatus.failure && state.devices.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              _Header(onShowAlerts: onShowAlerts, alarmCount: 0),
              const SizedBox(height: 20),
              ErrorView(
                message: state.errorMessage ?? 'Unable to load devices.',
                onRetry: () => context
                    .read<DevicesBloc>()
                    .add(const DevicesRefreshed()),
              ),
            ],
          );
        }

        return RefreshIndicator(
          color: AppTokens.of(context).accentColor,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await context.read<DevicesBloc>().refreshAndWait();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              _Header(
                onShowAlerts: onShowAlerts,
                alarmCount: state.stats.totalAlarms,
              ),
              const SizedBox(height: 18),
              _StatusStrip(state: state),
              const SizedBox(height: 16),
              _SearchBox(value: state.search),
              const SizedBox(height: 18),
              _FleetStats(stats: state.stats),
              const SizedBox(height: 20),
              SectionHeader('${state.filtered.length} devices'),
              const SizedBox(height: 12),
              if (state.isOffline) ...[
                _OfflineBanner(message: state.errorMessage),
                const SizedBox(height: 12),
              ],
              if (state.filtered.isEmpty)
                const EmptyView(
                  icon: Icons.watch_rounded,
                  title: 'No devices found',
                  message:
                      'Devices appear here as soon as the backend has live watch data.',
                )
              else
                for (final device in state.filtered) ...[
                  _DeviceTile(
                    device: device,
                    active: device.deviceId == state.activeDeviceId,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onShowAlerts, required this.alarmCount});

  final VoidCallback onShowAlerts;
  final int alarmCount;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profile) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stealthera',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onShowAlerts,
            icon: Badge(
              isLabelVisible: alarmCount > 0,
              backgroundColor: tokens.danger,
              label: Text(alarmCount > 99 ? '99+' : '$alarmCount'),
              child: const Icon(Icons.notifications_none_rounded, size: 26),
            ),
          ),
          const SizedBox(width: 6),
          ProfileAvatar(photoUrl: profile.profile?.photoUrl),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.state});

  final DevicesState state;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      glow: state.realtimeOpen,
      child: Row(
        children: [
          Icon(
            state.realtimeOpen ? Icons.sensors_rounded : Icons.sync_rounded,
            color: state.realtimeOpen ? tokens.success : tokens.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.realtimeOpen
                  ? 'Realtime stream connected'
                  : 'Polling backend for updates',
              style: AppTypography.monoStyle(
                12,
                FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (state.lastLiveAt != null)
            Text(
              DateFormat('h:mm:ss a').format(state.lastLiveAt!),
              style: AppTypography.monoStyle(
                11,
                FontWeight.w400,
                color: tokens.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (query) =>
          context.read<DevicesBloc>().add(DevicesSearched(query)),
      decoration: InputDecoration(
        hintText: 'Search device, model, nickname',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                onPressed: () => context
                    .read<DevicesBloc>()
                    .add(const DevicesSearched('')),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _FleetStats extends StatelessWidget {
  const _FleetStats({required this.stats});

  final FleetStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.watch_rounded,
            label: 'Total',
            value: stats.totalDevices.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.online_prediction_rounded,
            label: 'Online',
            value: stats.onlineDevices.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Alarms',
            value: stats.totalAlarms.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GlowCard(
      padding: const EdgeInsets.all(13),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.accentColor, size: 21),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.monoStyle(
              24,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              11,
              FontWeight.w400,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, this.active = false});

  final DeviceRow device;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final statusColor = device.isOnline ? tokens.success : tokens.textMuted;
    return GlowCard(
      glow: device.isOnline || active,
      borderColor: active ? tokens.accentColor.withValues(alpha: 0.6) : null,
      onTap: () {
        context.read<DevicesBloc>().add(DeviceSelected(device.deviceId));
        DeviceHubScreen.open(context, device.deviceId);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.watch_rounded, color: tokens.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 8),
                          _ActivePill(color: tokens.accentColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.deviceId,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoStyle(
                        11,
                        FontWeight.w400,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: device.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricMini(
                  icon: Icons.favorite_rounded,
                  label: 'HR',
                  value: _metric(device.heartRate),
                  unit: 'bpm',
                ),
              ),
              Expanded(
                child: _MetricMini(
                  icon: Icons.air_rounded,
                  label: 'SpO2',
                  value: _metric(device.bloodOxygen),
                  unit: '%',
                ),
              ),
              Expanded(
                child: _MetricMini(
                  icon: Icons.directions_walk_rounded,
                  label: 'Steps',
                  value: _metric(device.steps),
                  unit: '',
                ),
              ),
            ],
          ),
          if (device.updateTime.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Updated ${device.updateTime}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _metric(double value) => value == 0 ? '--' : formatNumber(value);
}

class _MetricMini extends StatelessWidget {
  const _MetricMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: tokens.textMuted, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.monoStyle(
            10,
            FontWeight.w400,
            color: tokens.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            unit.isEmpty ? value : '$value $unit',
            key: ValueKey('$label$value'),
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoStyle(
              13,
              FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ACTIVE',
        style: AppTypography.monoStyle(9, FontWeight.w700, color: color),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? 'unknown' : label,
        style: AppTypography.monoStyle(
          11,
          FontWeight.w700,
          color: color,
        ),
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
              message ?? 'Showing cached devices while the backend reconnects.',
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
