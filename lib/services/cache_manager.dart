import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Gestionnaire de cache universel et ultra-rapide basé sur Hive et de la mémoire vive (RAM).
class CacheManager {
  static const String _boxName = 'app_api_cache_box';
  static bool _initialized = false;
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, int> _expiryCache = {};

  /// Initialise Hive et ouvre la boîte de cache
  static Future<void> _init() async {
    if (_initialized) return;
    try {
      if (!kIsWeb) {
        await Hive.initFlutter();
      }
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      _initialized = true;
    } catch (e) {
      debugPrint("CacheManager init error: $e");
    }
  }

  /// Sauvegarde des données dans le cache (RAM + Hive) avec durée de vie (TTL)
  static Future<void> set(
    String key,
    dynamic data, {
    Duration ttl = const Duration(minutes: 15),
  }) async {
    final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
    _memoryCache[key] = data;
    _expiryCache[key] = expiry;

    try {
      await _init();
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final encoded = jsonEncode({
          'expiry': expiry,
          'data': data,
        });
        await box.put(key, encoded);
      }
    } catch (e) {
      debugPrint("CacheManager set error for $key: $e");
    }
  }

  /// Récupère les données depuis la mémoire vive ou le stockage local Hive
  static Future<dynamic> get(String key) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Accès mémoire vive ultra-rapide (RAM) < 1ms
    if (_memoryCache.containsKey(key) && _expiryCache.containsKey(key)) {
      if (_expiryCache[key]! > now) {
        return _memoryCache[key];
      } else {
        _memoryCache.remove(key);
        _expiryCache.remove(key);
      }
    }

    // 2. Accès disque Hive
    try {
      await _init();
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final raw = box.get(key);
        if (raw != null) {
          final Map<String, dynamic> payload = jsonDecode(raw.toString());
          final expiry = payload['expiry'] as int? ?? 0;

          if (expiry > now) {
            final data = payload['data'];
            _memoryCache[key] = data;
            _expiryCache[key] = expiry;
            return data;
          } else {
            await box.delete(key);
          }
        }
      }
    } catch (e) {
      debugPrint("CacheManager get error for $key: $e");
    }

    return null;
  }

  /// Supprime une clé spécifique du cache
  static Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    _expiryCache.remove(key);
    try {
      await _init();
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).delete(key);
      }
    } catch (e) {
      debugPrint("CacheManager invalidate error for $key: $e");
    }
  }

  /// Vide l'ensemble du cache
  static Future<void> clearAll() async {
    _memoryCache.clear();
    _expiryCache.clear();
    try {
      await _init();
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).clear();
      }
    } catch (e) {
      debugPrint("CacheManager clearAll error: $e");
    }
  }
}
