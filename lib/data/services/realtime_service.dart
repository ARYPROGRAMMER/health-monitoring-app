import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/device_models.dart';

/// A live SSE channel to the Stealthera API: opens `/stream` (fleet) or
/// `/device/:id/stream`, emits [LiveUpdate]s, and auto-reconnects with backoff.
class RealtimeChannel {
  RealtimeChannel({this.deviceId, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(headers: {if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey}));

  /// When null, subscribes to the whole-fleet stream.
  final String? deviceId;
  final Dio _dio;

  final _updates = StreamController<LiveUpdate>.broadcast();
  final _open = StreamController<bool>.broadcast();

  StreamSubscription<String>? _sub;
  CancelToken? _cancel;
  Timer? _retryTimer;
  bool _disposed = false;
  int _attempt = 0;
  bool _openState = false;

  /// Stream of decoded realtime sample pushes.
  Stream<LiveUpdate> get updates => _updates.stream;

  /// Emits true when the SSE handshake succeeds, false when the link drops.
  Stream<bool> get open => _open.stream;

  bool get isOpen => _openState;

  String get _url {
    final host = AppConfig.apiHost;
    return deviceId == null
        ? '$host/v1/api/stream'
        : '$host/v1/api/device/$deviceId/stream';
  }

  void connect() {
    if (_disposed) return;
    _start();
  }

  Future<void> _start() async {
    _cancel = CancelToken();
    try {
      final res = await _dio.get<ResponseBody>(
        _url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
          receiveTimeout: Duration.zero, // never time out a long-lived stream
        ),
        cancelToken: _cancel,
      );

      _attempt = 0;
      final buffer = StringBuffer();
      String? event;

      _sub = res.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.isEmpty) {
            _flush(event, buffer.toString());
            event = null;
            buffer.clear();
            return;
          }
          if (line.startsWith(':')) return; // heartbeat comment
          if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            buffer.write(line.substring(5).trim());
          }
        },
        onError: (Object e) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (e) {
      developer.log('SSE connect failed: $e', name: 'RealtimeChannel');
      _scheduleReconnect();
    }
  }

  void _flush(String? event, String data) {
    if (data.isEmpty) return;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      return;
    }
    if (json == null) return;

    if (event == 'connected') {
      _setOpen(true);
      return;
    }
    if (event == 'update' || event == null) {
      _setOpen(true);
      if (json.containsKey('device_id')) {
        _updates.add(LiveUpdate.fromJson(json));
      }
    }
  }

  void _setOpen(bool value) {
    if (_openState == value) return;
    _openState = value;
    if (!_open.isClosed) _open.add(value);
  }

  void _scheduleReconnect() {
    _setOpen(false);
    _sub?.cancel();
    _sub = null;
    if (_disposed) return;
    final delaySeconds = [2, 4, 8, 15, 30][_attempt.clamp(0, 4)];
    _attempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_disposed) _start();
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    _cancel?.cancel('disposed');
    await _sub?.cancel();
    await _updates.close();
    await _open.close();
  }
}
