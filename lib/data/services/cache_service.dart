import 'package:hive/hive.dart';

class CacheService {
  CacheService(this._box);

  final Box<dynamic> _box;

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _box.put(key, value);
  }

  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await _box.put(key, value);
  }

  Map<String, dynamic>? readJson(String key) {
    final value = _box.get(key);

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  List<Map<String, dynamic>> readJsonList(String key) {
    final value = _box.get(key);

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }
}
