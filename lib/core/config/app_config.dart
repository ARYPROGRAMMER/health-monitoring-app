import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central runtime configuration. Values come from `.env` first, then a
/// `--dart-define` override, then a safe default — so the app always boots,
/// even when no `.env` file is bundled or it fails to load.
class AppConfig {
  const AppConfig._();

  static const _defaultApiBaseUrl =
      'https://health-monitoring-app-hhiu.onrender.com/api';

  static const _dartDefineApiBaseUrl = String.fromEnvironment(
    'STEALTHERA_API_BASE_URL',
  );

  /// Reads a key from dotenv, returning null if dotenv is missing/uninitialised
  /// (accessing it before a successful [dotenv.load] throws otherwise).
  static String? _raw(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }

  static String _read(String key, {String fallback = ''}) {
    final value = _raw(key);
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String get apiBaseUrl {
    final configured = _read('API_BASE_URL');
    final candidate = _isValidUrl(configured)
        ? configured
        : (_isValidUrl(_dartDefineApiBaseUrl)
              ? _dartDefineApiBaseUrl
              : _defaultApiBaseUrl);
    final trimmed = candidate.endsWith('/')
        ? candidate.substring(0, candidate.length - 1)
        : candidate;
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  static bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  static bool get verboseLogging =>
      _read('ENABLE_VERBOSE_LOGGING', fallback: 'false').toLowerCase() ==
      'true';

  static Duration get pollInterval {
    final seconds = int.tryParse(_read('POLL_INTERVAL_SECONDS', fallback: '60')) ?? 60;
    // Guard against accidental 0/negative values that would hammer the backend.
    return Duration(seconds: seconds < 15 ? 60 : seconds);
  }

  static Duration get requestTimeout {
    final seconds =
        int.tryParse(_read('DEFAULT_TIMEOUT_SECONDS', fallback: '45')) ?? 45;
    return Duration(seconds: seconds < 5 ? 45 : seconds);
  }
}
