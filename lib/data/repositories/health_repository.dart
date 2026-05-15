import '../../core/constants/cache_keys.dart';
import '../models/health_models.dart';
import '../services/backend_api_client.dart';
import '../services/cache_service.dart';

class HealthRepository {
  HealthRepository({
    required BackendApiClient apiClient,
    required CacheService cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService;

  final BackendApiClient _apiClient;
  final CacheService _cacheService;

  DashboardSummaryModel? cachedDashboard() {
    final json = _cacheService.readJson(CacheKeys.dashboard);

    if (json == null) {
      return null;
    }

    return DashboardSummaryModel.fromJson(json).copyWith(isOffline: true);
  }

  HealthSettingsModel cachedSettings() {
    final json = _cacheService.readJson(CacheKeys.settings);

    if (json == null) {
      return HealthSettingsModel.defaults;
    }

    return HealthSettingsModel.fromJson(json);
  }

  Future<DashboardSummaryModel> fetchDashboard() async {
    final data = await _apiClient.getDashboard();
    final summary = DashboardSummaryModel.fromJson(data);
    await _cacheService.writeJson(CacheKeys.dashboard, summary.toJson());
    await _cacheService.writeJson(
      CacheKeys.settings,
      summary.settings.toJson(),
    );
    await _cacheService.writeJsonList(
      CacheKeys.alerts,
      summary.activeAlerts.map((alert) => alert.toJson()).toList(),
    );

    return summary;
  }

  Future<HealthSettingsModel> updateSettings(
    HealthSettingsModel settings,
  ) async {
    final data = await _apiClient.updateSettings(settings.toJson());
    final updated = HealthSettingsModel.fromJson(data);
    await _cacheService.writeJson(CacheKeys.settings, updated.toJson());

    return updated;
  }

  Future<List<HealthAlertModel>> fetchAlerts() async {
    final data = await _apiClient.getAlerts();
    await _cacheService.writeJsonList(CacheKeys.alerts, data);

    return data.map(HealthAlertModel.fromJson).toList();
  }

  Future<HealthAlertModel> resolveAlert(String alertId) async {
    final data = await _apiClient.updateAlertStatus(alertId, 'resolved');

    return HealthAlertModel.fromJson(data);
  }
}
