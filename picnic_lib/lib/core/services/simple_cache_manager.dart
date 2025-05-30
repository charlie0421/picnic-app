import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:picnic_lib/core/services/cache_policy.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  final String key;
  final String data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, String> headers;
  final int statusCode;
  final String? etag;
  final CachePriority priority;
  final String url;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.headers,
    required this.statusCode,
    this.etag,
    this.priority = CachePriority.medium,
    required this.url,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && statusCode >= 200 && statusCode < 400;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'headers': headers,
      'statusCode': statusCode,
      'etag': etag,
      'priority': priority.index,
      'url': url,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: json['data'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      headers: Map<String, String>.from(json['headers'] as Map),
      statusCode: json['statusCode'] as int,
      etag: json['etag'] as String?,
      priority: CachePriority.values[json['priority'] as int? ?? 1],
      url: json['url'] as String? ?? '',
    );
  }
}

class SimpleCacheManager {
  static const String _cachePrefix = 'http_cache_';
  static const String _invalidationPrefix = 'cache_invalidation_';
  static const int _maxMemoryCacheSize = 50;
  static const int _maxPersistentCacheSize = 100;

  late SharedPreferences _prefs;
  final Map<String, CacheEntry> _memoryCache = {};

  static SimpleCacheManager? _instance;

  static SimpleCacheManager get instance =>
      _instance ??= SimpleCacheManager._();

  SimpleCacheManager._();

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Process pending invalidations
      await _processPendingInvalidations();

      // Load frequently accessed items into memory cache
      await _loadFrequentItemsToMemory();

      // Clean expired entries on startup
      await _cleanExpiredEntries();

      logger.i('SimpleCacheManager initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize SimpleCacheManager',
          error: e, stackTrace: s);
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

  Future<CacheEntry?> get(String url, Map<String, String> headers,
      {bool isAuthenticated = false}) async {
    try {
      // Check if URL should be cached
      if (!CachePolicy.shouldCacheUrl(url)) {
        logger.d('URL not cacheable: $url');
        return null;
      }

      // Check auth requirements
      if (CachePolicy.requiresAuthForUrl(url) && !isAuthenticated) {
        logger.d('URL requires auth but user not authenticated: $url');
        return null;
      }

      final key = _generateCacheKey(url, headers);

      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (entry.isValid) {
          logger.d('Memory cache hit for URL: $url');
          return entry;
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check persistent cache
      final persistentKey = '$_cachePrefix$key';
      final jsonString = _prefs.getString(persistentKey);

      if (jsonString == null) {
        logger.d('Cache miss for URL: $url');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(json);

      if (entry.isExpired || !entry.isValid) {
        logger.d('Cache expired/invalid for URL: $url');
        await _prefs.remove(persistentKey);
        return null;
      }

      // Add to memory cache for faster access
      _addToMemoryCache(key, entry);

      logger.d('Persistent cache hit for URL: $url');
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
    bool isAuthenticated = false,
  }) async {
    try {
      // Check if URL should be cached
      if (!CachePolicy.shouldCacheUrl(url)) {
        logger.d('URL not cacheable, skipping: $url');
        return;
      }

      // Check auth requirements
      if (CachePolicy.requiresAuthForUrl(url) && !isAuthenticated) {
        logger
            .d('URL requires auth but user not authenticated, skipping: $url');
        return;
      }

      // Check size limits
      final maxSize = CachePolicy.getMaxSizeForUrl(url);
      if (responseBody.length > maxSize) {
        logger.d(
            'Response too large for caching: ${responseBody.length} > $maxSize');
        return;
      }

      final key = _generateCacheKey(url, headers);
      final now = DateTime.now();
      final duration = cacheDuration ?? CachePolicy.getTtlForUrl(url);
      final priority = CachePolicy.getPriorityForUrl(url);

      final entry = CacheEntry(
        key: key,
        data: responseBody,
        createdAt: now,
        expiresAt: now.add(duration),
        headers: responseHeaders ?? {},
        statusCode: statusCode,
        etag: etag,
        priority: priority,
        url: url,
      );

      // Store in memory cache
      _addToMemoryCache(key, entry);

      // Store in persistent cache based on priority and size
      if (_shouldPersistCache(url, responseBody.length, priority)) {
        final persistentKey = '$_cachePrefix$key';
        await _prefs.setString(persistentKey, jsonEncode(entry.toJson()));
      }

      await _manageCacheSize();

      logger.d(
          'Cached response for URL: $url (TTL: ${duration.inMinutes}min, Priority: ${priority.name})');
    } catch (e, s) {
      logger.e('Error storing cache entry', error: e, stackTrace: s);
    }
  }

  void _addToMemoryCache(String key, CacheEntry entry) {
    // Remove expired entries first
    _memoryCache.removeWhere((k, v) => v.isExpired);

    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // Remove lowest priority entries first, then oldest
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) {
          final priorityCompare =
              a.value.priority.index.compareTo(b.value.priority.index);
          if (priorityCompare != 0) return priorityCompare;
          return a.value.createdAt.compareTo(b.value.createdAt);
        });

      final entryToRemove = sortedEntries.first;
      _memoryCache.remove(entryToRemove.key);
      logger.d('Evicted memory cache entry: ${entryToRemove.value.url}');
    }

    _memoryCache[key] = entry;
  }

  bool _shouldPersistCache(String url, int dataSize, CachePriority priority) {
    // Always persist critical priority items (within size limits)
    if (priority == CachePriority.critical && dataSize <= 100 * 1024) {
      return true;
    }

    // Don't persist very large responses to avoid SharedPreferences bloat
    if (dataSize > 50 * 1024) {
      return false;
    }

    // Persist high priority items
    if (priority == CachePriority.high) {
      return true;
    }

    // Persist important API endpoints
    if (url.contains('/api/') ||
        url.contains('/rest/') ||
        url.contains('config') ||
        url.contains('user_profiles')) {
      return true;
    }

    return false;
  }

  Future<void> invalidateByPattern(String pattern) async {
    try {
      final regex = RegExp(pattern);
      final keysToRemove = <String>[];

      // Remove from memory cache
      _memoryCache.removeWhere((key, entry) {
        if (regex.hasMatch(entry.url)) {
          logger.d('Invalidating memory cache for: ${entry.url}');
          return true;
        }
        return false;
      });

      // Remove from persistent cache
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      for (final key in keys) {
        try {
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final url = json['url'] as String? ?? '';

            if (regex.hasMatch(url)) {
              keysToRemove.add(key);
              logger.d('Invalidating persistent cache for: $url');
            }
          }
        } catch (e) {
          // Remove invalid entries
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await _prefs.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        logger.i(
            'Invalidated ${keysToRemove.length} cache entries matching pattern: $pattern');
      }
    } catch (e, s) {
      logger.e('Error invalidating cache by pattern: $pattern',
          error: e, stackTrace: s);
    }
  }

  Future<void> invalidateForModification(String modifiedUrl) async {
    final patterns = CachePolicy.getInvalidationPatternsForUrl(modifiedUrl);

    for (final pattern in patterns) {
      await invalidateByPattern(pattern);
    }

    if (patterns.isNotEmpty) {
      logger.i('Invalidated cache for modification of: $modifiedUrl');
    }
  }

  Future<void> clearAuthenticatedCache() async {
    try {
      final keysToRemove = <String>[];

      // Remove from memory cache
      _memoryCache.removeWhere((key, entry) {
        if (CachePolicy.requiresAuthForUrl(entry.url)) {
          logger.d('Clearing authenticated cache for: ${entry.url}');
          return true;
        }
        return false;
      });

      // Remove from persistent cache
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      for (final key in keys) {
        try {
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final url = json['url'] as String? ?? '';

            if (CachePolicy.requiresAuthForUrl(url)) {
              keysToRemove.add(key);
            }
          }
        } catch (e) {
          // Remove invalid entries
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await _prefs.remove(key);
      }

      logger.i('Cleared ${keysToRemove.length} authenticated cache entries');
    } catch (e, s) {
      logger.e('Error clearing authenticated cache', error: e, stackTrace: s);
    }
  }

  Future<void> _processPendingInvalidations() async {
    try {
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_invalidationPrefix))
          .toList();

      for (final key in keys) {
        final pattern = key.substring(_invalidationPrefix.length);
        await invalidateByPattern(pattern);
        await _prefs.remove(key);
      }

      if (keys.isNotEmpty) {
        logger.i('Processed ${keys.length} pending invalidations');
      }
    } catch (e, s) {
      logger.e('Error processing pending invalidations',
          error: e, stackTrace: s);
    }
  }

  Future<void> _manageCacheSize() async {
    try {
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      if (keys.length > _maxPersistentCacheSize) {
        // Load all entries to sort by priority and creation time
        final entries = <String, CacheEntry>{};

        for (final key in keys) {
          try {
            final jsonString = _prefs.getString(key);
            if (jsonString != null) {
              final json = jsonDecode(jsonString) as Map<String, dynamic>;
              final entry = CacheEntry.fromJson(json);
              entries[key] = entry;
            }
          } catch (e) {
            // Remove invalid entries
            await _prefs.remove(key);
          }
        }

        // Sort by priority (ascending) then by creation time (ascending)
        final sortedKeys = entries.entries.toList()
          ..sort((a, b) {
            final priorityCompare =
                a.value.priority.index.compareTo(b.value.priority.index);
            if (priorityCompare != 0) return priorityCompare;
            return a.value.createdAt.compareTo(b.value.createdAt);
          });

        final keysToRemove = sortedKeys
            .take(keys.length -
                _maxPersistentCacheSize +
                10) // Remove extra to avoid frequent cleanup
            .map((e) => e.key);

        for (final key in keysToRemove) {
          await _prefs.remove(key);
        }

        logger.i('Cleaned ${keysToRemove.length} old cache entries');
      }
    } catch (e, s) {
      logger.e('Error managing cache size', error: e, stackTrace: s);
    }
  }

  Future<void> _loadFrequentItemsToMemory() async {
    try {
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      // Load entries and sort by priority
      final entries = <String, CacheEntry>{};

      for (final key in keys) {
        try {
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final entry = CacheEntry.fromJson(json);

            if (entry.isValid) {
              entries[key] = entry;
            }
          }
        } catch (e) {
          // Remove invalid entries
          await _prefs.remove(key);
        }
      }

      // Sort by priority (descending) and load top items
      final sortedEntries = entries.entries.toList()
        ..sort(
            (a, b) => b.value.priority.index.compareTo(a.value.priority.index));

      final itemsToLoad = sortedEntries.take(20);

      for (final entry in itemsToLoad) {
        final cacheKey = entry.key.substring(_cachePrefix.length);
        _memoryCache[cacheKey] = entry.value;
      }

      logger.d(
          'Loaded ${itemsToLoad.length} high-priority items to memory cache');
    } catch (e, s) {
      logger.e('Error loading items to memory', error: e, stackTrace: s);
    }
  }

  Future<void> _cleanExpiredEntries() async {
    try {
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      final expiredKeys = <String>[];

      for (final key in keys) {
        try {
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(json['expiresAt'] as String);

            if (DateTime.now().isAfter(expiresAt)) {
              expiredKeys.add(key);
            }
          }
        } catch (e) {
          // Remove invalid entries
          expiredKeys.add(key);
        }
      }

      for (final key in expiredKeys) {
        await _prefs.remove(key);
      }

      // Clean memory cache
      _memoryCache.removeWhere((key, entry) => entry.isExpired);

      if (expiredKeys.isNotEmpty) {
        logger.i('Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e, s) {
      logger.e('Error cleaning expired entries', error: e, stackTrace: s);
    }
  }

  Future<void> clear() async {
    try {
      final keys = _prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      for (final key in keys) {
        await _prefs.remove(key);
      }

      _memoryCache.clear();

      logger.i('Cache cleared successfully');
    } catch (e, s) {
      logger.e('Error clearing cache', error: e, stackTrace: s);
    }
  }

  Future<void> clearExpired() async {
    await _cleanExpiredEntries();
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      int totalSize = 0;
      int totalCount = 0;
      final priorityCounts = <CachePriority, int>{};

      for (final key in keys) {
        try {
          final value = _prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
            totalCount++;

            final json = jsonDecode(value) as Map<String, dynamic>;
            final priority =
                CachePriority.values[json['priority'] as int? ?? 1];
            priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
          }
        } catch (e) {
          // Skip invalid entries
        }
      }

      // Add memory cache stats
      for (final entry in _memoryCache.values) {
        totalSize += entry.data.length;
        totalCount++;
        priorityCounts[entry.priority] =
            (priorityCounts[entry.priority] ?? 0) + 1;
      }

      return {
        'totalSize': totalSize,
        'totalCount': totalCount,
        'memoryCount': _memoryCache.length,
        'persistentCount': keys.length,
        'priorityCounts': priorityCounts.map((k, v) => MapEntry(k.name, v)),
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'totalCount': 0,
        'memoryCount': 0,
        'persistentCount': 0,
        'priorityCounts': {},
      };
    }
  }

  Future<void> dispose() async {
    try {
      _memoryCache.clear();
      logger.i('SimpleCacheManager disposed');
    } catch (e, s) {
      logger.e('Error disposing SimpleCacheManager', error: e, stackTrace: s);
    }
  }
}
