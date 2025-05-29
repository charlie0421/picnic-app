import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/cache/cache_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _cacheBoxName = 'http_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  late Box<CacheEntry> _cacheBox;
  late Box<dynamic> _metadataBox;
  late SharedPreferences _prefs;

  static CacheManager? _instance;

  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CacheEntryAdapter());
      }

      _cacheBox = await Hive.openBox<CacheEntry>(_cacheBoxName);
      _metadataBox = await Hive.openBox(_metadataBoxName);
      _prefs = await SharedPreferences.getInstance();

      // Clean expired entries on startup
      await _cleanExpiredEntries();

      logger.i('CacheManager initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize CacheManager', error: e, stackTrace: s);
      rethrow;
    }
  }

  String _generateCacheKey(String url, Map<String, String> headers) {
    final normalizedHeaders = Map<String, String>.from(headers);
    normalizedHeaders.remove('authorization'); // 인증 헤더는 키에서 제외

    final keyData = '$url${jsonEncode(normalizedHeaders)}';
    final bytes = utf8.encode(keyData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<CacheEntry?> get(String url, Map<String, String> headers) async {
    try {
      final key = _generateCacheKey(url, headers);
      final entry = _cacheBox.get(key);

      if (entry == null) {
        logger.d('Cache miss for URL: $url');
        return null;
      }

      if (entry.isExpired) {
        logger.d('Cache expired for URL: $url');
        await _cacheBox.delete(key);
        return null;
      }

      if (!entry.isValid) {
        logger.d('Invalid cache entry for URL: $url');
        await _cacheBox.delete(key);
        return null;
      }

      logger.d('Cache hit for URL: $url');
      return entry;
    } catch (e, s) {
      logger.e('Error retrieving cache entry', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> put(
    String url,
    Map<String, String> headers,
    String responseBody,
    int statusCode, {
    Duration? cacheDuration,
    String? etag,
    Map<String, String>? responseHeaders,
  }) async {
    try {
      final key = _generateCacheKey(url, headers);
      final now = DateTime.now();
      final duration = cacheDuration ?? _defaultCacheDuration;

      final entry = CacheEntry(
        key: key,
        data: responseBody,
        createdAt: now,
        expiresAt: now.add(duration),
        headers: responseHeaders ?? {},
        statusCode: statusCode,
        etag: etag,
      );

      await _cacheBox.put(key, entry);
      await _updateCacheSize();

      logger.d('Cached response for URL: $url');
    } catch (e, s) {
      logger.e('Error storing cache entry', error: e, stackTrace: s);
    }
  }

  Future<void> _updateCacheSize() async {
    try {
      int totalSize = 0;
      for (final entry in _cacheBox.values) {
        totalSize += entry.data.length;
      }

      await _metadataBox.put('total_cache_size', totalSize);

      // If cache is too large, remove oldest entries
      if (totalSize > _maxCacheSize) {
        await _evictLeastRecentlyUsed();
      }
    } catch (e, s) {
      logger.e('Error updating cache size', error: e, stackTrace: s);
    }
  }

  Future<void> _evictLeastRecentlyUsed() async {
    try {
      final entries = _cacheBox.values.toList();
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      int removedSize = 0;
      int targetSize = _maxCacheSize ~/ 2; // Remove half when over limit

      for (final entry in entries) {
        if (removedSize >= targetSize) break;

        await _cacheBox.delete(entry.key);
        removedSize += entry.data.length;
      }

      logger.i('Evicted $removedSize bytes from cache');
    } catch (e, s) {
      logger.e('Error during cache eviction', error: e, stackTrace: s);
    }
  }

  Future<void> _cleanExpiredEntries() async {
    try {
      final expiredKeys = <String>[];

      for (final entry in _cacheBox.values) {
        if (entry.isExpired) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        await _cacheBox.delete(key);
      }

      if (expiredKeys.isNotEmpty) {
        logger.i('Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e, s) {
      logger.e('Error cleaning expired entries', error: e, stackTrace: s);
    }
  }

  Future<void> clear() async {
    try {
      await _cacheBox.clear();
      await _metadataBox.clear();
      logger.i('Cache cleared successfully');
    } catch (e, s) {
      logger.e('Error clearing cache', error: e, stackTrace: s);
    }
  }

  Future<void> clearExpired() async {
    await _cleanExpiredEntries();
  }

  Future<int> getCacheSize() async {
    try {
      return _metadataBox.get('total_cache_size', defaultValue: 0) as int;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getCacheCount() async {
    return _cacheBox.length;
  }

  bool _shouldCacheResponse(int statusCode, String url) {
    // Only cache successful responses
    if (statusCode < 200 || statusCode >= 400) {
      return false;
    }

    // Don't cache certain URLs (like real-time endpoints)
    if (url.contains('/realtime/') ||
        url.contains('/stream/') ||
        url.contains('/ws/')) {
      return false;
    }

    return true;
  }

  Future<void> dispose() async {
    try {
      await _cacheBox.close();
      await _metadataBox.close();
      logger.i('CacheManager disposed');
    } catch (e, s) {
      logger.e('Error disposing CacheManager', error: e, stackTrace: s);
    }
  }
}
