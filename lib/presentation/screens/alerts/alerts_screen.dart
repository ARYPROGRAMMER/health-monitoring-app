import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/health_models.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final alerts = state.summary?.alerts ?? const <HealthAlertModel>[];
        return RefreshIndicator(
          color: AppTokens.of(context).accentColor,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await context.read<DashboardBloc>().refreshAndWait();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            children: [
              Text(
                'Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              if (alerts.isEmpty)
                const EmptyView(
                  icon: Icons.shield_rounded,
                  title: 'No alerts',
                  message:
                      'Threshold breaches and wellness alerts will appear here with their resolution history.',
                )
              else ...[
                SectionHeader('${alerts.length} total'),
                const SizedBox(height: 12),
                for (final alert in alerts) ...[
                  _AlertTile(alert: alert),
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final HealthAlertModel alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final color = switch (alert.severity) {
      'critical' => tokens.danger,
      'warning' => tokens.warning,
      _ => tokens.accentColor,
    };

    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.warning_amber_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, h:mm a').format(alert.createdAt),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              if (!alert.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tokens.success.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Resolved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.message, style: theme.textTheme.bodyMedium),
          if (alert.isActive) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<DashboardBloc>().add(
                    DashboardAlertResolved(alert.id),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Resolve'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
