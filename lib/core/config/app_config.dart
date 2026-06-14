import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central runtime configuration. Values come from `.env` first, then a
/// `--dart-define` override, then a safe default — so the app always boots,
/// even when no `.env` file is bundled or it fails to load.
///
/// The Stealthera client API is mounted under `/v1/api`. [apiBaseUrl] always
/// resolves to `<host>/v1/api`, regardless of whether the configured value
/// already carries a path suffix.
class AppConfig {
  const AppConfig._();

  /// Default backend host. Override with `.env` `API_BASE_URL` or the
  /// `STEALTHERA_API_BASE_URL` dart-define (e.g. `http://10.0.2.2:3000` for an
  /// Android emulator pointing at a local server, or your machine's LAN IP).
  static const _defaultHost = 'https://health-monitoring-app-hhiu.onrender.com';

  static const _apiPrefix = '/v1/api';

  static const _dartDefineApiBaseUrl = String.fromEnvironment(
    'STEALTHERA_API_BASE_URL',
  );

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

  /// The fully-qualified API base, e.g. `https://host/v1/api`.
  static String get apiBaseUrl {
    final configured = _read('API_BASE_URL');
    final candidate = _isValidUrl(configured)
        ? configured
        : (_isValidUrl(_dartDefineApiBaseUrl)
              ? _dartDefineApiBaseUrl
              : _defaultHost);
    return _withApiPrefix(candidate);
  }

  /// Host root without the API prefix — used for SSE stream URLs and probes.
  static String get apiHost {
    final base = apiBaseUrl;
    return base.endsWith(_apiPrefix)
        ? base.substring(0, base.length - _apiPrefix.length)
        : base;
  }

  static String _withApiPrefix(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    // Strip any legacy/explicit suffix so we land on a clean host.
    for (final suffix in const ['/v1/api', '/api', '/v1']) {
      if (trimmed.endsWith(suffix)) {
        trimmed = trimmed.substring(0, trimmed.length - suffix.length);
        break;
      }
    }
    return '$trimmed$_apiPrefix';
  }

  static bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Optional `X-API-Key` for backends with `REQUIRE_API_KEY=true`.
  static String get apiKey => _read('API_KEY');

  /// Display timezone passed to the backend (`?tz=`). Backend default is IST.
  static String get timezone => _read('DISPLAY_TIMEZONE', fallback: 'Asia/Kolkata');

  static bool get verboseLogging =>
      _read('ENABLE_VERBOSE_LOGGING', fallback: 'false').toLowerCase() == 'true';

  /// Foreground poll cadence for the active device dashboard / fleet list.
  /// Acts as the realtime fallback when the SSE stream has no live updates.
  static Duration get pollInterval {
    final seconds =
        int.tryParse(_read('POLL_INTERVAL_SECONDS', fallback: '20')) ?? 20;
    return Duration(seconds: seconds < 8 ? 20 : seconds);
  }

  static Duration get requestTimeout {
    final seconds =
        int.tryParse(_read('DEFAULT_TIMEOUT_SECONDS', fallback: '45')) ?? 45;
    return Duration(seconds: seconds < 5 ? 45 : seconds);
  }
}
