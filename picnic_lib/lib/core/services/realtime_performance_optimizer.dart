import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

/// 실시간 기능 성능 최적화 서비스
/// 연결 풀링, 스로틀링, 메모리 관리 등을 담당합니다.
class RealtimePerformanceOptimizer {
  static final RealtimePerformanceOptimizer _instance = RealtimePerformanceOptimizer._internal();
  factory RealtimePerformanceOptimizer() => _instance;
  RealtimePerformanceOptimizer._internal();

  // 연결 풀링 관리
  final Map<String, ConnectionPool> _connectionPools = {};
  final Map<String, Timer> _connectionTimers = {};
  
  // 스로틀링 관리
  final Map<String, PublishSubject> _throttledStreams = {};
  final Map<String, Timer> _throttleTimers = {};
  
  // 성능 모니터링
  final PerformanceMetrics _metrics = PerformanceMetrics();
  Timer? _metricsTimer;
  
  // 메모리 관리
  Timer? _memoryCleanupTimer;
  final int _maxCachedConnections = 20;
  final Duration _connectionTimeout = const Duration(minutes: 5);
  final Duration _throttleInterval = const Duration(milliseconds: 100);

  /// 성능 최적화 서비스 초기화
  Future<void> initialize() async {
    logger.i('🚀 Realtime Performance Optimizer 초기화');
    
    // 정기적인 메트릭스 수집 시작
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _collectMetrics();
    });
    
    // 메모리 정리 타이머 시작
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _performMemoryCleanup();
    });
    
    logger.i('✅ Performance Optimizer 초기화 완료');
  }

  /// 연결 풀 생성 또는 가져오기
  ConnectionPool getOrCreateConnectionPool(String poolId, {int maxConnections = 5}) {
    if (!_connectionPools.containsKey(poolId)) {
      _connectionPools[poolId] = ConnectionPool(
        poolId: poolId,
        maxConnections: maxConnections,
      );
      logger.d('📦 새로운 연결 풀 생성: $poolId (최대 $maxConnections개)');
    }
    
    // 풀 사용 시점 갱신
    _updatePoolLastUsed(poolId);
    
    return _connectionPools[poolId]!;
  }

  /// 스로틀된 스트림 생성
  Stream<T> createThrottledStream<T>(
    String streamId,
    Stream<T> sourceStream, {
    Duration? throttleInterval,
  }) {
    final interval = throttleInterval ?? _throttleInterval;
    
    if (_throttledStreams.containsKey(streamId)) {
      return _throttledStreams[streamId]!.stream.cast<T>();
    }
    
    final subject = PublishSubject<T>();
    _throttledStreams[streamId] = subject;
    
    // 스로틀링 적용
    sourceStream
        .throttleTime(interval)
        .listen(
          (data) {
            if (!subject.isClosed) {
              subject.add(data);
              _metrics.recordEvent('throttled_event', streamId);
            }
          },
          onError: (error) {
            if (!subject.isClosed) {
              subject.addError(error);
            }
          },
          onDone: () {
            _closeThrottledStream(streamId);
          },
        );
    
    logger.d('🕰️ 스로틀된 스트림 생성: $streamId (${interval.inMilliseconds}ms)');
    return subject.stream;
  }

  /// 배치 처리를 위한 스트림 생성
  Stream<List<T>> createBatchedStream<T>(
    String streamId,
    Stream<T> sourceStream, {
    int batchSize = 10,
    Duration batchTimeout = const Duration(seconds: 1),
  }) {
    return sourceStream
        .bufferTime(batchTimeout, batchSize)
        .where((batch) => batch.isNotEmpty)
        .doOnData((batch) {
          _metrics.recordBatch(streamId, batch.length);
          logger.d('📦 배치 처리: $streamId (${batch.length}개 아이템)');
        });
  }

  /// 우선순위 기반 스트림 병합
  Stream<T> createPriorityMergedStream<T>(
    Map<String, Stream<T>> prioritizedStreams,
  ) {
    final controllers = <String, StreamController<T>>{};
    final subscriptions = <String, StreamSubscription<T>>{};
    final outputController = StreamController<T>();
    
    // 우선순위 순으로 정렬 (높은 우선순위부터)
    final sortedStreams = prioritizedStreams.entries.toList()
      ..sort((a, b) => _getPriorityLevel(b.key).compareTo(_getPriorityLevel(a.key)));
    
    for (final entry in sortedStreams) {
      final streamId = entry.key;
      final stream = entry.value;
      
      subscriptions[streamId] = stream.listen(
        (data) {
          if (!outputController.isClosed) {
            outputController.add(data);
            _metrics.recordPriorityEvent(streamId);
          }
        },
        onError: (error) {
          if (!outputController.isClosed) {
            outputController.addError(error);
          }
        },
      );
    }
    
    // 정리 함수 등록
    outputController.onCancel = () {
      for (final subscription in subscriptions.values) {
        subscription.cancel();
      }
      subscriptions.clear();
    };
    
    return outputController.stream;
  }

  /// 페이로드 압축 최적화
  Map<String, dynamic> optimizePayload(Map<String, dynamic> payload) {
    final optimized = <String, dynamic>{};
    
    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // 불필요한 필드 제거
      if (_isUnnecessaryField(key, value)) {
        continue;
      }
      
      // 데이터 압축
      optimized[key] = _compressValue(value);
    }
    
    final originalSize = payload.toString().length;
    final optimizedSize = optimized.toString().length;
    final reduction = ((originalSize - optimizedSize) / originalSize * 100).round();
    
    if (reduction > 10) {
      logger.d('🗜️ 페이로드 최적화: ${reduction}% 감소 ($originalSize -> $optimizedSize bytes)');
    }
    
    _metrics.recordPayloadOptimization(originalSize, optimizedSize);
    
    return optimized;
  }

  /// 로드 테스트 실행
  Future<LoadTestResult> runLoadTest({
    required int concurrentConnections,
    required Duration testDuration,
    required String testScenario,
  }) async {
    logger.i('🧪 로드 테스트 시작: $testScenario ($concurrentConnections 동시 연결, ${testDuration.inSeconds}초)');
    
    final startTime = DateTime.now();
    final results = <ConnectionTestResult>[];
    final futures = <Future<ConnectionTestResult>>[];
    
    // 동시 연결 생성
    for (int i = 0; i < concurrentConnections; i++) {
      futures.add(_runSingleConnectionTest(
        connectionId: 'load_test_$i',
        duration: testDuration,
        scenario: testScenario,
      ));
    }
    
    // 모든 연결 테스트 완료 대기
    try {
      results.addAll(await Future.wait(futures));
    } catch (e) {
      logger.e('로드 테스트 중 오류 발생', error: e);
    }
    
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    
    final loadTestResult = LoadTestResult(
      scenario: testScenario,
      concurrentConnections: concurrentConnections,
      totalDuration: totalDuration,
      connectionResults: results,
      successfulConnections: results.where((r) => r.success).length,
      averageLatency: _calculateAverageLatency(results),
      throughput: _calculateThroughput(results, totalDuration),
    );
    
    logger.i('✅ 로드 테스트 완료: 성공률 ${(loadTestResult.successRate * 100).toStringAsFixed(1)}%');
    
    return loadTestResult;
  }

  /// 현재 성능 메트릭스 가져오기
  PerformanceMetrics getCurrentMetrics() {
    return _metrics.copy();
  }

  /// 성능 최적화 추천사항 생성
  List<OptimizationRecommendation> generateRecommendations() {
    final recommendations = <OptimizationRecommendation>[];
    
    // 연결 풀 사용률 분석
    for (final entry in _connectionPools.entries) {
      final poolId = entry.key;
      final pool = entry.value;
      
      if (pool.utilizationRate > 0.8) {
        recommendations.add(OptimizationRecommendation(
          type: OptimizationType.connectionPooling,
          priority: RecommendationPriority.high,
          description: '연결 풀 "$poolId"의 사용률이 높습니다 (${(pool.utilizationRate * 100).round()}%). 풀 크기 증가를 고려하세요.',
          action: 'increasePoolSize',
          targetResource: poolId,
        ));
      }
    }
    
    // 스로틀링 효과 분석
    if (_metrics.throttledEventsCount > 1000) {
      recommendations.add(OptimizationRecommendation(
        type: OptimizationType.throttling,
        priority: RecommendationPriority.medium,
        description: '스로틀링된 이벤트가 많습니다 (${_metrics.throttledEventsCount}개). 스로틀 간격 조정을 고려하세요.',
        action: 'adjustThrottleInterval',
        targetResource: 'global_throttling',
      ));
    }
    
    // 메모리 사용량 분석
    if (_connectionPools.length > _maxCachedConnections) {
      recommendations.add(OptimizationRecommendation(
        type: OptimizationType.memoryManagement,
        priority: RecommendationPriority.high,
        description: '활성 연결 풀이 너무 많습니다 (${_connectionPools.length}개). 메모리 정리가 필요합니다.',
        action: 'performMemoryCleanup',
        targetResource: 'memory_management',
      ));
    }
    
    // 페이로드 크기 분석
    if (_metrics.averagePayloadSize > 10000) {
      recommendations.add(OptimizationRecommendation(
        type: OptimizationType.payloadOptimization,
        priority: RecommendationPriority.medium,
        description: '평균 페이로드 크기가 큽니다 (${_metrics.averagePayloadSize} bytes). 데이터 압축을 고려하세요.',
        action: 'enablePayloadCompression',
        targetResource: 'payload_optimization',
      ));
    }
    
    return recommendations;
  }

  /// 리소스 정리
  void dispose() {
    logger.i('🧹 Performance Optimizer 리소스 정리');
    
    // 타이머 정리
    _metricsTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    
    // 연결 타이머 정리
    for (final timer in _connectionTimers.values) {
      timer.cancel();
    }
    _connectionTimers.clear();
    
    // 스로틀 타이머 정리
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
    
    // 스트림 정리
    for (final subject in _throttledStreams.values) {
      subject.close();
    }
    _throttledStreams.clear();
    
    // 연결 풀 정리
    _connectionPools.clear();
    
    logger.i('✅ Performance Optimizer 정리 완료');
  }

  // Private methods

  void _updatePoolLastUsed(String poolId) {
    _connectionTimers[poolId]?.cancel();
    _connectionTimers[poolId] = Timer(_connectionTimeout, () {
      _removeUnusedPool(poolId);
    });
  }

  void _removeUnusedPool(String poolId) {
    _connectionPools.remove(poolId);
    _connectionTimers.remove(poolId);
    logger.d('🗑️ 사용하지 않는 연결 풀 제거: $poolId');
  }

  void _closeThrottledStream(String streamId) {
    final subject = _throttledStreams.remove(streamId);
    subject?.close();
    _throttleTimers[streamId]?.cancel();
    _throttleTimers.remove(streamId);
    logger.d('🔒 스로틀된 스트림 종료: $streamId');
  }

  void _collectMetrics() {
    _metrics.update(
      activeConnectionPools: _connectionPools.length,
      activeThrottledStreams: _throttledStreams.length,
      timestamp: DateTime.now(),
    );
    
    logger.d('📊 성능 메트릭스 수집: 풀 ${_connectionPools.length}개, 스트림 ${_throttledStreams.length}개');
  }

  void _performMemoryCleanup() {
    final before = _connectionPools.length + _throttledStreams.length;
    
    // 사용하지 않는 연결 풀 정리
    final unusedPools = <String>[];
    for (final entry in _connectionPools.entries) {
      if (entry.value.isIdle) {
        unusedPools.add(entry.key);
      }
    }
    
    for (final poolId in unusedPools) {
      _removeUnusedPool(poolId);
    }
    
    // 닫힌 스트림 정리
    final closedStreams = <String>[];
    for (final entry in _throttledStreams.entries) {
      if (entry.value.isClosed) {
        closedStreams.add(entry.key);
      }
    }
    
    for (final streamId in closedStreams) {
      _throttledStreams.remove(streamId);
    }
    
    final after = _connectionPools.length + _throttledStreams.length;
    
    if (before > after) {
      logger.i('🧽 메모리 정리 완료: ${before - after}개 리소스 해제');
    }
  }

  int _getPriorityLevel(String streamId) {
    if (streamId.contains('critical')) return 100;
    if (streamId.contains('high')) return 80;
    if (streamId.contains('medium')) return 60;
    if (streamId.contains('low')) return 40;
    return 50; // default priority
  }

  bool _isUnnecessaryField(String key, dynamic value) {
    // null 값 제거
    if (value == null) return true;
    
    // 빈 문자열 제거
    if (value is String && value.isEmpty) return true;
    
    // 빈 리스트/맵 제거
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    
    // 메타데이터 필드 제거 (필요에 따라 조정)
    if (key.startsWith('_') || key.contains('metadata')) return true;
    
    return false;
  }

  dynamic _compressValue(dynamic value) {
    if (value is String && value.length > 100) {
      // 긴 문자열은 요약
      return '${value.substring(0, 97)}...';
    }
    
    if (value is List && value.length > 10) {
      // 긴 리스트는 일부만 포함
      return [...value.take(10), '...'];
    }
    
    return value;
  }

  Future<ConnectionTestResult> _runSingleConnectionTest({
    required String connectionId,
    required Duration duration,
    required String scenario,
  }) async {
    final startTime = DateTime.now();
    int messagesSent = 0;
    int messagesReceived = 0;
    final latencies = <int>[];
    
    try {
      // 시뮬레이션된 연결 테스트
      final endTime = startTime.add(duration);
      
      while (DateTime.now().isBefore(endTime)) {
        final messageStart = DateTime.now();
        
        // 메시지 전송 시뮬레이션
        await Future.delayed(Duration(milliseconds: math.Random().nextInt(50) + 10));
        messagesSent++;
        
        // 응답 수신 시뮬레이션
        await Future.delayed(Duration(milliseconds: math.Random().nextInt(30) + 5));
        messagesReceived++;
        
        final latency = DateTime.now().difference(messageStart).inMilliseconds;
        latencies.add(latency);
        
        // CPU 부하 방지를 위한 짧은 대기
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      return ConnectionTestResult(
        connectionId: connectionId,
        success: true,
        duration: DateTime.now().difference(startTime),
        messagesSent: messagesSent,
        messagesReceived: messagesReceived,
        averageLatency: latencies.isEmpty ? 0 : latencies.reduce((a, b) => a + b) / latencies.length,
        errorMessage: null,
      );
    } catch (e) {
      return ConnectionTestResult(
        connectionId: connectionId,
        success: false,
        duration: DateTime.now().difference(startTime),
        messagesSent: messagesSent,
        messagesReceived: messagesReceived,
        averageLatency: 0,
        errorMessage: e.toString(),
      );
    }
  }

  double _calculateAverageLatency(List<ConnectionTestResult> results) {
    final validResults = results.where((r) => r.success && r.averageLatency > 0);
    if (validResults.isEmpty) return 0;
    
    return validResults.map((r) => r.averageLatency).reduce((a, b) => a + b) / validResults.length;
  }

  double _calculateThroughput(List<ConnectionTestResult> results, Duration totalDuration) {
    final totalMessages = results.map((r) => r.messagesReceived).reduce((a, b) => a + b);
    return totalMessages / totalDuration.inSeconds;
  }
}

/// 연결 풀 클래스
class ConnectionPool {
  final String poolId;
  final int maxConnections;
  final Queue<String> _availableConnections = Queue<String>();
  final Set<String> _busyConnections = <String>{};
  DateTime lastUsed = DateTime.now();

  ConnectionPool({
    required this.poolId,
    required this.maxConnections,
  });

  bool get isIdle => _busyConnections.isEmpty && DateTime.now().difference(lastUsed).inMinutes > 5;
  double get utilizationRate => _busyConnections.length / maxConnections;
  int get availableCount => _availableConnections.length;
  int get busyCount => _busyConnections.length;

  String? acquireConnection() {
    lastUsed = DateTime.now();
    
    if (_availableConnections.isNotEmpty) {
      final connectionId = _availableConnections.removeFirst();
      _busyConnections.add(connectionId);
      return connectionId;
    }
    
    if (_busyConnections.length < maxConnections) {
      final connectionId = '${poolId}_conn_${DateTime.now().millisecondsSinceEpoch}';
      _busyConnections.add(connectionId);
      return connectionId;
    }
    
    return null; // 풀이 가득 참
  }

  void releaseConnection(String connectionId) {
    if (_busyConnections.remove(connectionId)) {
      _availableConnections.add(connectionId);
      lastUsed = DateTime.now();
    }
  }
}

/// 성능 메트릭스 클래스
class PerformanceMetrics {
  int throttledEventsCount = 0;
  int batchProcessedCount = 0;
  int priorityEventsCount = 0;
  int payloadOptimizationsCount = 0;
  int totalPayloadSizeBefore = 0;
  int totalPayloadSizeAfter = 0;
  int activeConnectionPools = 0;
  int activeThrottledStreams = 0;
  DateTime lastUpdated = DateTime.now();

  double get averagePayloadSize => payloadOptimizationsCount > 0 
      ? totalPayloadSizeBefore / payloadOptimizationsCount 
      : 0;

  double get payloadCompressionRatio => totalPayloadSizeBefore > 0
      ? (totalPayloadSizeBefore - totalPayloadSizeAfter) / totalPayloadSizeBefore
      : 0;

  void recordEvent(String type, String streamId) {
    switch (type) {
      case 'throttled_event':
        throttledEventsCount++;
        break;
    }
    lastUpdated = DateTime.now();
  }

  void recordBatch(String streamId, int batchSize) {
    batchProcessedCount += batchSize;
    lastUpdated = DateTime.now();
  }

  void recordPriorityEvent(String streamId) {
    priorityEventsCount++;
    lastUpdated = DateTime.now();
  }

  void recordPayloadOptimization(int sizeBefore, int sizeAfter) {
    payloadOptimizationsCount++;
    totalPayloadSizeBefore += sizeBefore;
    totalPayloadSizeAfter += sizeAfter;
    lastUpdated = DateTime.now();
  }

  void update({
    required int activeConnectionPools,
    required int activeThrottledStreams,
    required DateTime timestamp,
  }) {
    this.activeConnectionPools = activeConnectionPools;
    this.activeThrottledStreams = activeThrottledStreams;
    lastUpdated = timestamp;
  }

  PerformanceMetrics copy() {
    final copy = PerformanceMetrics();
    copy.throttledEventsCount = throttledEventsCount;
    copy.batchProcessedCount = batchProcessedCount;
    copy.priorityEventsCount = priorityEventsCount;
    copy.payloadOptimizationsCount = payloadOptimizationsCount;
    copy.totalPayloadSizeBefore = totalPayloadSizeBefore;
    copy.totalPayloadSizeAfter = totalPayloadSizeAfter;
    copy.activeConnectionPools = activeConnectionPools;
    copy.activeThrottledStreams = activeThrottledStreams;
    copy.lastUpdated = lastUpdated;
    return copy;
  }
}

/// 로드 테스트 결과
class LoadTestResult {
  final String scenario;
  final int concurrentConnections;
  final Duration totalDuration;
  final List<ConnectionTestResult> connectionResults;
  final int successfulConnections;
  final double averageLatency;
  final double throughput;

  LoadTestResult({
    required this.scenario,
    required this.concurrentConnections,
    required this.totalDuration,
    required this.connectionResults,
    required this.successfulConnections,
    required this.averageLatency,
    required this.throughput,
  });

  double get successRate => successfulConnections / concurrentConnections;
  int get failedConnections => concurrentConnections - successfulConnections;
  
  Map<String, dynamic> toJson() {
    return {
      'scenario': scenario,
      'concurrent_connections': concurrentConnections,
      'total_duration_seconds': totalDuration.inSeconds,
      'successful_connections': successfulConnections,
      'failed_connections': failedConnections,
      'success_rate': successRate,
      'average_latency_ms': averageLatency,
      'throughput_msg_per_sec': throughput,
      'connection_results': connectionResults.map((r) => r.toJson()).toList(),
    };
  }
}

/// 단일 연결 테스트 결과
class ConnectionTestResult {
  final String connectionId;
  final bool success;
  final Duration duration;
  final int messagesSent;
  final int messagesReceived;
  final double averageLatency;
  final String? errorMessage;

  ConnectionTestResult({
    required this.connectionId,
    required this.success,
    required this.duration,
    required this.messagesSent,
    required this.messagesReceived,
    required this.averageLatency,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId,
      'success': success,
      'duration_seconds': duration.inSeconds,
      'messages_sent': messagesSent,
      'messages_received': messagesReceived,
      'average_latency_ms': averageLatency,
      'error_message': errorMessage,
    };
  }
}

/// 최적화 추천사항
class OptimizationRecommendation {
  final OptimizationType type;
  final RecommendationPriority priority;
  final String description;
  final String action;
  final String targetResource;

  OptimizationRecommendation({
    required this.type,
    required this.priority,
    required this.description,
    required this.action,
    required this.targetResource,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'priority': priority.toString(),
      'description': description,
      'action': action,
      'target_resource': targetResource,
    };
  }
}

enum OptimizationType {
  connectionPooling,
  throttling,
  memoryManagement,
  payloadOptimization,
  loadBalancing,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}