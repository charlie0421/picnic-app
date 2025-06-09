import 'dart:async';
import 'dart:collection';

import 'package:picnic_lib/core/utils/logger.dart';

/// 검색 결과 캐싱 서비스
/// 메모리 기반 LRU 캐시를 사용하여 검색 성능을 최적화
class SearchCacheService {
  static final SearchCacheService _instance = SearchCacheService._internal();
  factory SearchCacheService() => _instance;
  SearchCacheService._internal();

  // LRU 캐시 구현
  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();
  
  /// 최대 캐시 크기
  static const int _maxCacheSize = 100;
  
  /// 캐시 만료 시간 (기본 5분)
  static const Duration _defaultExpiration = Duration(minutes: 5);

  /// 캐시에서 데이터 조회
  /// 
  /// [key] 캐시 키
  /// Returns: 캐시된 데이터 또는 null
  T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null) {
      return null;
    }
    
    // 만료 확인
    if (entry.isExpired) {
      _cache.remove(key);
      logger.d('Cache expired for key: $key');
      return null;
    }
    
    // LRU 업데이트 (최근 사용된 항목을 맨 뒤로 이동)
    _cache.remove(key);
    _cache[key] = entry;
    
    logger.d('Cache hit for key: $key');
    return entry.data as T?;
  }

  /// 캐시에 데이터 저장
  /// 
  /// [key] 캐시 키
  /// [data] 저장할 데이터
  /// [expiration] 만료 시간 (기본값: 5분)
  void put<T>(String key, T data, {Duration? expiration}) {
    // 캐시 크기 제한 확인
    if (_cache.length >= _maxCacheSize) {
      // 가장 오래된 항목 제거 (LRU)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      logger.d('Cache evicted oldest entry: $oldestKey');
    }
    
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiration: expiration ?? _defaultExpiration,
    );
    
    _cache[key] = entry;
    logger.d('Cache stored for key: $key');
  }

  /// 특정 키의 캐시 삭제
  void remove(String key) {
    _cache.remove(key);
    logger.d('Cache removed for key: $key');
  }

  /// 패턴에 맞는 캐시 삭제
  /// 
  /// [pattern] 삭제할 키 패턴 (예: 'artist_*')
  void removeByPattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    logger.d('Cache removed ${keysToRemove.length} entries matching pattern: $pattern');
  }

  /// 전체 캐시 삭제
  void clear() {
    final count = _cache.length;
    _cache.clear();
    logger.d('Cache cleared $count entries');
  }

  /// 만료된 캐시 항목 정리
  void cleanupExpired() {
    final keysToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    logger.d('Cache cleanup removed ${keysToRemove.length} expired entries');
  }

  /// 캐시 통계 정보
  CacheStats get stats {
    final now = DateTime.now();
    int expiredCount = 0;
    
    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      }
    }
    
    return CacheStats(
      totalEntries: _cache.length,
      expiredEntries: expiredCount,
      maxSize: _maxCacheSize,
      hitRate: 0.0, // 실제 구현에서는 hit/miss 카운터 필요
    );
  }

  /// 캐시 키 존재 여부 확인
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// 캐시 크기 조회
  int get size => _cache.length;

  /// 캐시가 비어있는지 확인
  bool get isEmpty => _cache.isEmpty;

  /// 캐시에 데이터가 있는지 확인
  bool get isNotEmpty => _cache.isNotEmpty;
}

/// 캐시 엔트리 클래스
class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
  });

  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;

  /// 캐시 만료 여부 확인
  bool get isExpired {
    return DateTime.now().difference(timestamp) > expiration;
  }

  /// 남은 만료 시간
  Duration get remainingTime {
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = expiration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// 캐시 통계 정보 클래스
class CacheStats {
  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.maxSize,
    required this.hitRate,
  });

  final int totalEntries;
  final int expiredEntries;
  final int maxSize;
  final double hitRate;

  int get activeEntries => totalEntries - expiredEntries;
  double get usageRate => totalEntries / maxSize;

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, active: $activeEntries, '
           'expired: $expiredEntries, usage: ${(usageRate * 100).toStringAsFixed(1)}%, '
           'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
} 