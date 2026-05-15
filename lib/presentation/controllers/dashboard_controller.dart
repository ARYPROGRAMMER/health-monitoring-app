import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/health_models.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/notification_service.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummaryModel?>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardSummaryModel?> {
  @override
  Future<DashboardSummaryModel?> build() async {
    final cached = ref.watch(healthRepositoryProvider).cachedDashboard();
    unawaited(refresh(silent: true));

    return cached;
  }

  Future<void> refresh({bool silent = false}) async {
    final previous = state.asData?.value;

    if (!silent) {
      state = const AsyncLoading();
    }

    try {
      final summary = await ref.read(healthRepositoryProvider).fetchDashboard();
      await ref
          .read(appThemeModeProvider.notifier)
          .applySettings(summary.settings);

      if (summary.settings.notificationsEnabled) {
        await NotificationService.instance.showHealthAlerts(
          summary.activeAlerts,
        );
      }

      state = AsyncData(summary);
    } catch (error, stackTrace) {
      final cached = ref.read(healthRepositoryProvider).cachedDashboard();

      if (cached != null || previous != null) {
        state = AsyncData(
          (cached ?? previous!).copyWith(
            isOffline: true,
            errorMessage:
                'Showing cached health data while the backend is unavailable.',
          ),
        );
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateSettings(HealthSettingsModel settings) async {
    final current = state.asData?.value;
    state = const AsyncLoading();

    try {
      final updated = await ref
          .read(healthRepositoryProvider)
          .updateSettings(settings);
      await ref.read(appThemeModeProvider.notifier).applySettings(updated);

      if (current == null) {
        await refresh();
        return;
      }

      state = AsyncData(current.copyWith(settings: updated));
      await refresh(silent: true);
    } catch (error, stackTrace) {
      if (current != null) {
        state = AsyncData(current);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> resolveAlert(String alertId) async {
    final current = state.asData?.value;

    if (current == null) {
      return;
    }

    try {
      await ref.read(healthRepositoryProvider).resolveAlert(alertId);
      state = AsyncData(
        current.copyWith(
          alerts: current.alerts.map((alert) {
            if (alert.id == alertId) {
              return HealthAlertModel(
                id: alert.id,
                type: alert.type,
                severity: alert.severity,
                title: alert.title,
                message: alert.message,
                metricValue: alert.metricValue,
                thresholdValue: alert.thresholdValue,
                status: 'resolved',
                createdAt: alert.createdAt,
                resolvedAt: DateTime.now(),
              );
            }

            return alert;
          }).toList(),
          activeAlerts: current.activeAlerts
              .where((alert) => alert.id != alertId)
              .toList(),
        ),
      );
      await refresh(silent: true);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> syncReading(HealthReadingModel reading) async {
    final current = state.asData?.value;

    try {
      final summary = await ref
          .read(healthRepositoryProvider)
          .syncReading(reading);
      await ref
          .read(appThemeModeProvider.notifier)
          .applySettings(summary.settings);

      if (summary.settings.notificationsEnabled) {
        await NotificationService.instance.showHealthAlerts(
          summary.activeAlerts,
        );
      }

      state = AsyncData(summary);
    } catch (_) {
      if (current != null) {
        state = AsyncData(current);
      }

      rethrow;
    }
  }
}
