import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/activity_stat_card.dart';
import '../../../core/widgets/date_strip.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/metric_grid_tile.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/route_map_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../device/device_hub_screen.dart';
import '../metrics/metric_detail_screen.dart';
import '../metrics/metric_kind.dart';
import '../../widgets/add_reading_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onShowAlerts, super.key});

  final VoidCallback onShowAlerts;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        if (state.status == DashboardStatus.loading && summary == null) {
          return const LoadingView();
        }
        if (state.status == DashboardStatus.failure && summary == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              _Header(onShowAlerts: widget.onShowAlerts, alertCount: 0),
              const SizedBox(height: 20),
              ErrorView(
                message: state.errorMessage ?? 'Unable to reach the backend.',
                onRetry: () => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
              ),
            ],
          );
        }

        final alertCount = summary?.activeAlerts.length ?? 0;
        final hasVitals = summary?.hasVitals ?? false;

        return RefreshIndicator(
          color: AppTokens.of(context).accentColor,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await context.read<DashboardBloc>().refreshAndWait();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              _Header(onShowAlerts: widget.onShowAlerts, alertCount: alertCount),
              const SizedBox(height: 18),
              DateStrip(
                selected: _selectedDay,
                onSelect: (day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: 22),
              if (summary?.isOffline == true) ...[
                _OfflineBanner(message: summary?.errorMessage),
                const SizedBox(height: 16),
              ],
              const SectionHeader("Today's Activity"),
              const SizedBox(height: 14),
              ActivityStatCard(
                icon: Icons.directions_walk_rounded,
                value: summary?.activity == null
                    ? '--'
                    : formatNumber(summary!.activity!.value),
                unit: 'Steps',
                onTap: () => MetricDetailScreen.open(context, MetricKind.steps),
              ),
              const SizedBox(height: 12),
              ActivityStatCard(
                icon: Icons.local_fire_department_rounded,
                value: summary?.activity == null
                    ? '--'
                    : estimateCalories(summary!.activity!.value)
                          .toStringAsFixed(2),
                unit: 'Kcal',
                onTap: () =>
                    MetricDetailScreen.open(context, MetricKind.calories),
              ),
              const SizedBox(height: 16),
              const RouteMapCard(),
              const SizedBox(height: 20),
              if (!hasVitals)
                EmptyView(
                  icon: Icons.sensors_rounded,
                  title: 'No readings yet',
                  message:
                      'Add your first reading to populate vitals, alerts, and your offline cache.',
                  action: FilledButton.icon(
                    onPressed: () => AddReadingSheet.show(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add reading'),
                  ),
                )
              else
                const _MetricGrid(),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onShowAlerts, required this.alertCount});

  final VoidCallback onShowAlerts;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profile) {
        return Row(
          children: [
            Expanded(
              child: Text(
                'Hi ${profile.firstName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onShowAlerts,
              icon: Badge(
                isLabelVisible: alertCount > 0,
                backgroundColor: tokens.danger,
                label: Text('$alertCount'),
                child: const Icon(Icons.notifications_none_rounded, size: 26),
              ),
            ),
            const SizedBox(width: 4),
            ProfileAvatar(
              photoUrl: profile.profile?.photoUrl,
              onTap: () => DeviceHubScreen.open(context),
            ),
          ],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    Widget tile(MetricKind kind) => MetricGridTile(
      icon: kind.icon,
      label: kind.title,
      onTap: () => MetricDetailScreen.open(context, kind),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tile(MetricKind.heart)),
            const SizedBox(width: 12),
            Expanded(child: tile(MetricKind.steps)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tile(MetricKind.spo2)),
            const SizedBox(width: 12),
            Expanded(child: tile(MetricKind.calories)),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: MetricGridTile(
                icon: Icons.help_outline_rounded,
                label: 'Coming Soon...',
                comingSoon: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricGridTile(
                icon: Icons.help_outline_rounded,
                label: 'Coming Soon...',
                comingSoon: true,
              ),
            ),
          ],
        ),
      ],
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
              message ?? 'Showing cached data.',
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
