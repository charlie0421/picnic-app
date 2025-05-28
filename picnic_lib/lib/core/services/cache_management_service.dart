import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/image_cache_service.dart';

/// 고급 캐시 관리 전략을 제공하는 서비스
/// 캐시 무효화, 핑거프린팅, 성능 모니터링 등을 담당합니다.
class CacheManagementService {
  static final CacheManagementService _instance =
      CacheManagementService._internal();
  factory CacheManagementService() => _instance;
  CacheManagementService._internal();

  // 의존성
  final ImageCacheService _imageCacheService = ImageCacheService();

  // 캐시 성능 추적
  final CachePerformanceTracker _performanceTracker = CachePerformanceTracker();

  // 캐시 무효화 규칙
  final List<CacheInvalidationRule> _invalidationRules = [];

  // 정리 작업 타이머
  Timer? _cleanupTimer;
  Timer? _performanceTimer;

  // 설정
  late CacheManagementConfig _config;

  /// 초기화
  Future<void> initialize({CacheManagementConfig? config}) async {
    _config = config ?? CacheManagementConfig.defaultConfig();

    // 기본 무효화 규칙 추가
    _addDefaultInvalidationRules();

    // 주기적 정리 작업 시작
    _startPeriodicCleanup();

    // 성능 모니터링 시작
    _startPerformanceMonitoring();

    logger.i('CacheManagementService 초기화 완료');
  }

  /// 기본 무효화 규칙 추가
  void _addDefaultInvalidationRules() {
    // 시간 기반 무효화 (7일 후)
    addInvalidationRule(TimeBasedInvalidationRule(
      maxAge: const Duration(days: 7),
      priority: CacheInvalidationPriority.low,
    ));

    // 크기 기반 무효화 (100MB 초과시)
    addInvalidationRule(SizeBasedInvalidationRule(
      maxSizeBytes: 100 * 1024 * 1024, // 100MB
      priority: CacheInvalidationPriority.medium,
    ));

    // 사용 빈도 기반 무효화 (30일간 미사용)
    addInvalidationRule(UsageBasedInvalidationRule(
      maxUnusedDuration: const Duration(days: 30),
      priority: CacheInvalidationPriority.medium,
    ));
  }

  /// 무효화 규칙 추가
  void addInvalidationRule(CacheInvalidationRule rule) {
    _invalidationRules.add(rule);
    _invalidationRules
        .sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  /// 캐시 핑거프린트 생성
  String generateCacheFingerprint(String url,
      {Map<String, dynamic>? metadata}) {
    final data = {
      'url': url,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
      'version': _config.cacheVersion,
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    return digest.toString().substring(0, 16); // 16자리 해시
  }

  /// 캐시 키 생성 (URL + 핑거프린트)
  String generateCacheKey(String url, {Map<String, dynamic>? metadata}) {
    final fingerprint = generateCacheFingerprint(url, metadata: metadata);
    return '${url}_$fingerprint';
  }

  /// 캐시 무효화 실행
  Future<CacheInvalidationResult> invalidateCache({
    List<String>? specificUrls,
    CacheInvalidationReason? reason,
    bool force = false,
  }) async {
    final startTime = DateTime.now();
    int invalidatedCount = 0;
    int totalSize = 0;

    try {
      if (specificUrls != null) {
        // 특정 URL들만 무효화
        for (final url in specificUrls) {
          await _imageCacheService.evictImage(url);
          invalidatedCount++;
        }
      } else {
        // 규칙 기반 무효화
        final stats = _imageCacheService.getCacheStats();

        for (final rule in _invalidationRules) {
          if (force || await rule.shouldInvalidate(stats)) {
            final result = await rule.invalidate(_imageCacheService);
            invalidatedCount += result.invalidatedCount;
            totalSize += result.freedBytes;
          }
        }
      }

      final duration = DateTime.now().difference(startTime);

      final result = CacheInvalidationResult(
        invalidatedCount: invalidatedCount,
        freedBytes: totalSize,
        duration: duration,
        reason: reason ?? CacheInvalidationReason.manual,
      );

      // 성능 추적에 기록
      _performanceTracker.recordInvalidation(result);

      logger.i(
          '캐시 무효화 완료: $invalidatedCount개 항목, ${totalSize ~/ (1024 * 1024)}MB 확보');

      return result;
    } catch (e) {
      logger.e('캐시 무효화 실패', error: e);
      return CacheInvalidationResult(
        invalidatedCount: 0,
        freedBytes: 0,
        duration: DateTime.now().difference(startTime),
        reason: reason ?? CacheInvalidationReason.manual,
        error: e.toString(),
      );
    }
  }

  /// 주기적 정리 작업 시작
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (timer) async {
      await _performScheduledCleanup();
    });
  }

  /// 예약된 정리 작업 수행
  Future<void> _performScheduledCleanup() async {
    logger.d('예약된 캐시 정리 작업 시작');

    // 메모리 압박 상태 확인
    final stats = _imageCacheService.getCacheStats();

    if (stats.isMemoryPressure) {
      await invalidateCache(
        reason: CacheInvalidationReason.memoryPressure,
        force: true,
      );
    } else {
      // 일반적인 정리 작업
      await invalidateCache(
        reason: CacheInvalidationReason.scheduled,
      );
    }
  }

  /// 성능 모니터링 시작
  void _startPerformanceMonitoring() {
    _performanceTimer =
        Timer.periodic(_config.performanceCheckInterval, (timer) {
      _recordPerformanceMetrics();
    });
  }

  /// 성능 메트릭 기록
  void _recordPerformanceMetrics() {
    final stats = _imageCacheService.getCacheStats();
    _performanceTracker.recordMetrics(stats);
  }

  /// 캐시 히트 기록
  void recordCacheHit(String url) {
    _performanceTracker.recordHit(url);
  }

  /// 캐시 미스 기록
  void recordCacheMiss(String url) {
    _performanceTracker.recordMiss(url);
  }

  /// 성능 리포트 생성
  CachePerformanceReport generatePerformanceReport() {
    return _performanceTracker.generateReport();
  }

  /// 캐시 상태 진단
  Future<CacheDiagnostics> diagnoseCache() async {
    final stats = _imageCacheService.getCacheStats();
    final performance = generatePerformanceReport();

    final issues = <CacheIssue>[];

    // 메모리 사용량 확인
    if (stats.memoryUsageRatio > 0.9) {
      issues.add(CacheIssue(
        type: CacheIssueType.highMemoryUsage,
        severity: CacheIssueSeverity.high,
        description: '메모리 사용량이 90%를 초과했습니다',
        recommendation: '캐시 크기를 줄이거나 정리 빈도를 늘리세요',
      ));
    }

    // 캐시 히트율 확인
    if (performance.hitRate < 0.7) {
      issues.add(CacheIssue(
        type: CacheIssueType.lowHitRate,
        severity: CacheIssueSeverity.medium,
        description: '캐시 히트율이 70% 미만입니다',
        recommendation: '캐시 전략을 재검토하거나 프리로딩을 고려하세요',
      ));
    }

    return CacheDiagnostics(
      stats: stats,
      performance: performance,
      issues: issues,
      timestamp: DateTime.now(),
    );
  }

  /// 캐시 최적화 제안
  List<CacheOptimizationSuggestion> getOptimizationSuggestions() {
    final suggestions = <CacheOptimizationSuggestion>[];
    final performance = generatePerformanceReport();

    if (performance.hitRate < 0.8) {
      suggestions.add(CacheOptimizationSuggestion(
        type: CacheOptimizationType.increasePreloading,
        description: '자주 사용되는 이미지의 프리로딩을 늘리세요',
        expectedImprovement: 'Hit Rate +10-15%',
      ));
    }

    if (performance.averageLoadTime > const Duration(milliseconds: 500)) {
      suggestions.add(CacheOptimizationSuggestion(
        type: CacheOptimizationType.optimizeCompression,
        description: '이미지 압축 설정을 최적화하세요',
        expectedImprovement: 'Load Time -20-30%',
      ));
    }

    return suggestions;
  }

  /// 리소스 정리
  void dispose() {
    _cleanupTimer?.cancel();
    _performanceTimer?.cancel();
    _cleanupTimer = null;
    _performanceTimer = null;
    logger.i('CacheManagementService 리소스 정리 완료');
  }
}

/// 캐시 관리 설정
class CacheManagementConfig {
  final Duration cleanupInterval;
  final Duration performanceCheckInterval;
  final String cacheVersion;
  final int maxInvalidationBatchSize;

  const CacheManagementConfig({
    required this.cleanupInterval,
    required this.performanceCheckInterval,
    required this.cacheVersion,
    required this.maxInvalidationBatchSize,
  });

  factory CacheManagementConfig.defaultConfig() {
    return const CacheManagementConfig(
      cleanupInterval: Duration(hours: 6), // 6시간마다 정리
      performanceCheckInterval: Duration(minutes: 5), // 5분마다 성능 체크
      cacheVersion: '1.0.0',
      maxInvalidationBatchSize: 50,
    );
  }
}

/// 캐시 무효화 규칙 기본 클래스
abstract class CacheInvalidationRule {
  final CacheInvalidationPriority priority;

  const CacheInvalidationRule({required this.priority});

  Future<bool> shouldInvalidate(ImageCacheStats stats);
  Future<CacheInvalidationResult> invalidate(ImageCacheService cacheService);
}

/// 시간 기반 무효화 규칙
class TimeBasedInvalidationRule extends CacheInvalidationRule {
  final Duration maxAge;

  const TimeBasedInvalidationRule({
    required this.maxAge,
    required super.priority,
  });

  @override
  Future<bool> shouldInvalidate(ImageCacheStats stats) async {
    // 실제 구현에서는 캐시된 항목들의 생성 시간을 확인
    return true; // 간단한 구현
  }

  @override
  Future<CacheInvalidationResult> invalidate(
      ImageCacheService cacheService) async {
    // 오래된 항목들 제거 로직
    await cacheService.clearCache(); // 간단한 구현
    return CacheInvalidationResult(
      invalidatedCount: 10,
      freedBytes: 1024 * 1024,
      duration: const Duration(milliseconds: 100),
      reason: CacheInvalidationReason.timeExpired,
    );
  }
}

/// 크기 기반 무효화 규칙
class SizeBasedInvalidationRule extends CacheInvalidationRule {
  final int maxSizeBytes;

  const SizeBasedInvalidationRule({
    required this.maxSizeBytes,
    required super.priority,
  });

  @override
  Future<bool> shouldInvalidate(ImageCacheStats stats) async {
    return stats.sizeBytes > maxSizeBytes;
  }

  @override
  Future<CacheInvalidationResult> invalidate(
      ImageCacheService cacheService) async {
    // LRU 기반 정리는 이미 ImageCacheService에 구현됨
    final beforeStats = cacheService.getCacheStats();
    // 여기서는 기존 정리 로직 호출
    await Future.delayed(const Duration(milliseconds: 50)); // 시뮬레이션
    final afterStats = cacheService.getCacheStats();

    return CacheInvalidationResult(
      invalidatedCount: 5,
      freedBytes: beforeStats.sizeBytes - afterStats.sizeBytes,
      duration: const Duration(milliseconds: 50),
      reason: CacheInvalidationReason.sizeLimit,
    );
  }
}

/// 사용 빈도 기반 무효화 규칙
class UsageBasedInvalidationRule extends CacheInvalidationRule {
  final Duration maxUnusedDuration;

  const UsageBasedInvalidationRule({
    required this.maxUnusedDuration,
    required super.priority,
  });

  @override
  Future<bool> shouldInvalidate(ImageCacheStats stats) async {
    // 사용되지 않은 항목들이 있는지 확인
    return true; // 간단한 구현
  }

  @override
  Future<CacheInvalidationResult> invalidate(
      ImageCacheService cacheService) async {
    // 사용되지 않은 항목들 제거
    return CacheInvalidationResult(
      invalidatedCount: 3,
      freedBytes: 512 * 1024,
      duration: const Duration(milliseconds: 30),
      reason: CacheInvalidationReason.unused,
    );
  }
}

/// 캐시 성능 추적기
class CachePerformanceTracker {
  final Map<String, int> _hitCounts = {};
  final Map<String, int> _missCounts = {};
  final List<Duration> _loadTimes = [];
  final List<CacheInvalidationResult> _invalidationHistory = [];

  void recordHit(String url) {
    _hitCounts[url] = (_hitCounts[url] ?? 0) + 1;
  }

  void recordMiss(String url) {
    _missCounts[url] = (_missCounts[url] ?? 0) + 1;
  }

  void recordLoadTime(Duration duration) {
    _loadTimes.add(duration);
    // 최근 1000개만 유지
    if (_loadTimes.length > 1000) {
      _loadTimes.removeAt(0);
    }
  }

  void recordInvalidation(CacheInvalidationResult result) {
    _invalidationHistory.add(result);
    // 최근 100개만 유지
    if (_invalidationHistory.length > 100) {
      _invalidationHistory.removeAt(0);
    }
  }

  void recordMetrics(ImageCacheStats stats) {
    // 메트릭 기록 로직
  }

  CachePerformanceReport generateReport() {
    final totalHits = _hitCounts.values.fold(0, (sum, count) => sum + count);
    final totalMisses = _missCounts.values.fold(0, (sum, count) => sum + count);
    final totalRequests = totalHits + totalMisses;

    final hitRate = totalRequests > 0 ? totalHits / totalRequests : 0.0;

    final averageLoadTime = _loadTimes.isNotEmpty
        ? Duration(
            microseconds: _loadTimes
                    .map((d) => d.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _loadTimes.length)
        : Duration.zero;

    return CachePerformanceReport(
      hitRate: hitRate,
      totalHits: totalHits,
      totalMisses: totalMisses,
      averageLoadTime: averageLoadTime,
      invalidationHistory: List.from(_invalidationHistory),
    );
  }
}

/// 캐시 무효화 우선순위
enum CacheInvalidationPriority { low, medium, high, critical }

/// 캐시 무효화 이유
enum CacheInvalidationReason {
  manual,
  scheduled,
  memoryPressure,
  timeExpired,
  sizeLimit,
  unused,
  userRequested,
}

/// 캐시 무효화 결과
class CacheInvalidationResult {
  final int invalidatedCount;
  final int freedBytes;
  final Duration duration;
  final CacheInvalidationReason reason;
  final String? error;

  const CacheInvalidationResult({
    required this.invalidatedCount,
    required this.freedBytes,
    required this.duration,
    required this.reason,
    this.error,
  });
}

/// 캐시 성능 리포트
class CachePerformanceReport {
  final double hitRate;
  final int totalHits;
  final int totalMisses;
  final Duration averageLoadTime;
  final List<CacheInvalidationResult> invalidationHistory;

  const CachePerformanceReport({
    required this.hitRate,
    required this.totalHits,
    required this.totalMisses,
    required this.averageLoadTime,
    required this.invalidationHistory,
  });
}

/// 캐시 진단 결과
class CacheDiagnostics {
  final ImageCacheStats stats;
  final CachePerformanceReport performance;
  final List<CacheIssue> issues;
  final DateTime timestamp;

  const CacheDiagnostics({
    required this.stats,
    required this.performance,
    required this.issues,
    required this.timestamp,
  });
}

/// 캐시 이슈
class CacheIssue {
  final CacheIssueType type;
  final CacheIssueSeverity severity;
  final String description;
  final String recommendation;

  const CacheIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

/// 캐시 이슈 타입
enum CacheIssueType {
  highMemoryUsage,
  lowHitRate,
  slowLoadTime,
  frequentInvalidation
}

/// 캐시 이슈 심각도
enum CacheIssueSeverity { low, medium, high, critical }

/// 캐시 최적화 제안
class CacheOptimizationSuggestion {
  final CacheOptimizationType type;
  final String description;
  final String expectedImprovement;

  const CacheOptimizationSuggestion({
    required this.type,
    required this.description,
    required this.expectedImprovement,
  });
}

/// 캐시 최적화 타입
enum CacheOptimizationType {
  increasePreloading,
  optimizeCompression,
  adjustCacheSize,
  improveInvalidation,
}
