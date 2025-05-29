import 'package:picnic_lib/core/utils/logger.dart';

enum CachePriority {
  low,
  medium,
  high,
  critical,
}

enum CacheStrategy {
  cacheFirst, // 캐시 우선, 없으면 네트워크
  networkFirst, // 네트워크 우선, 실패하면 캐시
  cacheOnly, // 캐시만 사용
  networkOnly, // 네트워크만 사용
  staleWhileRevalidate, // 캐시 반환 후 백그라운드에서 업데이트
}

class CacheRule {
  final String pattern;
  final Duration ttl;
  final CachePriority priority;
  final CacheStrategy strategy;
  final bool requiresAuth;
  final int maxSize;

  const CacheRule({
    required this.pattern,
    required this.ttl,
    this.priority = CachePriority.medium,
    this.strategy = CacheStrategy.cacheFirst,
    this.requiresAuth = false,
    this.maxSize = 50 * 1024, // 50KB default
  });
}

class CachePolicy {
  static const List<CacheRule> _rules = [
    // User profiles - high priority, long TTL
    CacheRule(
      pattern: r'/rest/v1/user_profiles',
      ttl: Duration(hours: 6),
      priority: CachePriority.high,
      strategy: CacheStrategy.staleWhileRevalidate,
      requiresAuth: true,
    ),

    // Configuration data - critical priority, very long TTL
    CacheRule(
      pattern: r'/rest/v1/config',
      ttl: Duration(hours: 24),
      priority: CachePriority.critical,
      strategy: CacheStrategy.cacheFirst,
    ),

    // Product data - medium priority, medium TTL
    CacheRule(
      pattern: r'/rest/v1/products',
      ttl: Duration(hours: 2),
      priority: CachePriority.medium,
      strategy: CacheStrategy.staleWhileRevalidate,
    ),

    // Artist data - medium priority, long TTL
    CacheRule(
      pattern: r'/rest/v1/artist',
      ttl: Duration(hours: 4),
      priority: CachePriority.medium,
      strategy: CacheStrategy.cacheFirst,
    ),

    // Popup data - low priority, short TTL
    CacheRule(
      pattern: r'/rest/v1/popup',
      ttl: Duration(minutes: 30),
      priority: CachePriority.low,
      strategy: CacheStrategy.networkFirst,
    ),

    // Static content - high priority, very long TTL
    CacheRule(
      pattern: r'\.(jpg|jpeg|png|gif|webp|svg|css|js)$',
      ttl: Duration(days: 7),
      priority: CachePriority.high,
      strategy: CacheStrategy.cacheFirst,
      maxSize: 500 * 1024, // 500KB for images
    ),

    // API functions - low priority, short TTL
    CacheRule(
      pattern: r'/functions/v1/',
      ttl: Duration(minutes: 15),
      priority: CachePriority.low,
      strategy: CacheStrategy.networkFirst,
    ),

    // Default rule for other API endpoints
    CacheRule(
      pattern: r'/rest/v1/',
      ttl: Duration(hours: 1),
      priority: CachePriority.medium,
      strategy: CacheStrategy.cacheFirst,
    ),
  ];

  static CacheRule? getRuleForUrl(String url) {
    try {
      for (final rule in _rules) {
        final regex = RegExp(rule.pattern);
        if (regex.hasMatch(url)) {
          logger.d('Cache rule matched for $url: ${rule.pattern}');
          return rule;
        }
      }
      logger.d('No cache rule matched for $url, using default');
      return null;
    } catch (e, s) {
      logger.e('Error matching cache rule for $url', error: e, stackTrace: s);
      return null;
    }
  }

  static Duration getTtlForUrl(String url) {
    final rule = getRuleForUrl(url);
    return rule?.ttl ?? const Duration(hours: 1);
  }

  static CachePriority getPriorityForUrl(String url) {
    final rule = getRuleForUrl(url);
    return rule?.priority ?? CachePriority.medium;
  }

  static CacheStrategy getStrategyForUrl(String url) {
    final rule = getRuleForUrl(url);
    return rule?.strategy ?? CacheStrategy.cacheFirst;
  }

  static bool shouldCacheUrl(String url) {
    // Don't cache real-time endpoints
    if (url.contains('/realtime/') ||
        url.contains('/stream/') ||
        url.contains('/ws/')) {
      return false;
    }

    // Don't cache auth endpoints (except for some specific ones)
    if (url.contains('/auth/') && !url.contains('/auth/session')) {
      return false;
    }

    // Don't cache POST/PUT/DELETE operations
    return true;
  }

  static bool requiresAuthForUrl(String url) {
    final rule = getRuleForUrl(url);
    return rule?.requiresAuth ?? false;
  }

  static int getMaxSizeForUrl(String url) {
    final rule = getRuleForUrl(url);
    return rule?.maxSize ?? 50 * 1024;
  }

  static List<String> getInvalidationPatternsForUrl(String url) {
    // Define which cache entries should be invalidated when certain URLs are modified
    final invalidationMap = <String, List<String>>{
      r'/rest/v1/user_profiles': [
        r'/rest/v1/user_profiles',
        r'/rest/v1/user_agreement',
      ],
      r'/rest/v1/products': [
        r'/rest/v1/products',
      ],
      r'/rest/v1/config': [
        r'/rest/v1/config',
      ],
    };

    for (final entry in invalidationMap.entries) {
      final regex = RegExp(entry.key);
      if (regex.hasMatch(url)) {
        return entry.value;
      }
    }

    return [];
  }
}
