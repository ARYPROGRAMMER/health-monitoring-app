import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/device_models.dart';
import '../../blocs/alarms/alarms_bloc.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmsBloc, AlarmsState>(
      builder: (context, state) {
        if (state.status == AlarmsStatus.loading && state.alarms.isEmpty) {
          return const LoadingView();
        }
        if (state.status == AlarmsStatus.failure && state.alarms.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            children: [
              _Header(count: 0),
              const SizedBox(height: 20),
              ErrorView(
                message: state.errorMessage ?? 'Unable to load alarms.',
                onRetry: () =>
                    context.read<AlarmsBloc>().add(const AlarmsRefreshed()),
              ),
            ],
          );
        }
        return RefreshIndicator(
          color: AppTokens.of(context).accentColor,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await context.read<AlarmsBloc>().refreshAndWait();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            children: [
              _Header(count: state.alarms.length),
              const SizedBox(height: 14),
              const _Filters(),
              const SizedBox(height: 16),
              if (state.isOffline) ...[
                _OfflineBanner(message: state.errorMessage),
                const SizedBox(height: 12),
              ],
              if (state.alarms.isEmpty)
                const EmptyView(
                  icon: Icons.shield_rounded,
                  title: 'No alarms',
                  message:
                      'SOS, fall, sedentary, and device alarms from the backend appear here.',
                )
              else ...[
                SectionHeader('${state.criticalCount} critical'),
                const SizedBox(height: 12),
                for (final alarm in state.alarms) ...[
                  _AlarmTile(alarm: alarm),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Alerts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        _CountPill(count: count),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmsBloc, AlarmsState>(
      buildWhen: (p, n) => p.typeFilter != n.typeFilter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'All', type: null, selected: state.typeFilter == null),
              const SizedBox(width: 8),
              _FilterChip(label: 'SOS', type: 'sos', selected: state.typeFilter == 'sos'),
              const SizedBox(width: 8),
              _FilterChip(label: 'Fall', type: 'fall', selected: state.typeFilter == 'fall'),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sedentary',
                type: 'sedentary',
                selected: state.typeFilter == 'sedentary',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.type,
    required this.selected,
  });

  final String label;
  final String? type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) =>
          context.read<AlarmsBloc>().add(AlarmsFilterChanged(type)),
      selectedColor: tokens.accentColor.withValues(alpha: 0.22),
      backgroundColor: tokens.elevatedCard,
      side: BorderSide(
        color: selected ? tokens.accentColor : tokens.cardBorder,
      ),
      label: Text(label),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.alarm});

  final AlarmRow alarm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final color = alarm.isSos
        ? tokens.danger
        : alarm.isFall
            ? tokens.warning
            : tokens.accentColor;
    return GlowCard(
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon(alarm), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.type.isEmpty ? 'Alarm' : alarm.type,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _time(alarm.time),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                alarm.deviceId,
                style: AppTypography.monoStyle(
                  11,
                  FontWeight.w700,
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alarm.content.isEmpty ? 'No alarm message attached.' : alarm.content,
            style: theme.textTheme.bodyMedium,
          ),
          if (alarm.location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 18, color: tokens.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alarm.location,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (alarm.latLng != null)
                  TextButton.icon(
                    onPressed: () => _openMap(alarm),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Map'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _icon(AlarmRow alarm) {
    if (alarm.isSos) return Icons.sos_rounded;
    if (alarm.isFall) return Icons.personal_injury_rounded;
    if (alarm.isSedentary) return Icons.event_seat_rounded;
    return Icons.warning_amber_rounded;
  }

  String _time(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '--' : raw;
    return DateFormat('MMM d, h:mm a').format(parsed.toLocal());
  }

  Future<void> _openMap(AlarmRow alarm) async {
    final point = alarm.latLng;
    if (point == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.$1},${point.$2}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count total',
        style: AppTypography.monoStyle(
          11,
          FontWeight.w700,
          color: tokens.danger,
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
              message ?? 'Showing the last alarm list.',
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
