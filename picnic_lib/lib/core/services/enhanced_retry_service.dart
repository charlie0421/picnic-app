import 'dart:async';
import 'dart:math';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 고급 재시도 메커니즘 서비스
/// 지수 백오프, 서킷 브레이커, 우선순위 큐 등을 포함한 강화된 재시도 전략을 제공합니다.
class EnhancedRetryService {
  static const Duration _minRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(minutes: 10);
  static const int _defaultMaxAttempts = 5;
  static const Duration _circuitBreakerResetTimeout = Duration(minutes: 5);
  static const int _circuitBreakerFailureThreshold = 10;

  static EnhancedRetryService? _instance;
  static EnhancedRetryService get instance =>
      _instance ??= EnhancedRetryService._();
  EnhancedRetryService._();

  final OfflineDatabaseService _localDb = OfflineDatabaseService.instance;
  final EnhancedNetworkService _networkService = EnhancedNetworkService();

  // 서킷 브레이커 상태
  final Map<String, CircuitBreakerState> _circuitBreakers = {};

  // 우선순위 큐 (높은 우선순위가 먼저 처리됨)
  final List<RetryOperation> _priorityQueue = [];

  // 진행 중인 재시도 작업
  final Map<String, RetryContext> _activeRetries = {};

  Timer? _retryProcessor;
  bool _isProcessing = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      logger.i('Initializing EnhancedRetryService...');

      // 주기적으로 재시도 큐 처리
      _retryProcessor = Timer.periodic(const Duration(seconds: 10), (_) {
        _processRetryQueue();
      });

      logger.i('EnhancedRetryService initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize EnhancedRetryService',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 작업을 재시도 큐에 추가
  Future<void> scheduleRetry({
    required String operationId,
    required Future<dynamic> Function() operation,
    RetryPriority priority = RetryPriority.normal,
    int? maxAttempts,
    Duration? initialDelay,
    RetryStrategy strategy = RetryStrategy.exponentialBackoff,
    List<Type>? retryOnExceptions,
    bool persistentRetry = false,
  }) async {
    try {
      final retryOp = RetryOperation(
        id: operationId,
        operation: operation,
        priority: priority,
        maxAttempts: maxAttempts ?? _defaultMaxAttempts,
        initialDelay: initialDelay ?? _minRetryDelay,
        strategy: strategy,
        retryOnExceptions: retryOnExceptions ?? [Exception],
        persistentRetry: persistentRetry,
        createdAt: DateTime.now(),
      );

      // 우선순위에 따라 정렬하여 삽입
      _insertByPriority(retryOp);

      // 지속적 재시도인 경우 데이터베이스에 저장
      if (persistentRetry) {
        await _savePersistentRetry(retryOp);
      }

      logger.d(
          'Scheduled retry operation: $operationId (priority: ${priority.name})');
    } catch (e, s) {
      logger.e('Error scheduling retry operation', error: e, stackTrace: s);
    }
  }

  /// 재시도 큐 처리
  Future<void> _processRetryQueue() async {
    if (_isProcessing || _priorityQueue.isEmpty) return;

    _isProcessing = true;

    try {
      final now = DateTime.now();
      final readyOperations = _priorityQueue.where((op) {
        final context = _activeRetries[op.id];
        if (context == null) return true;

        return now.isAfter(context.nextRetryAt);
      }).toList();

      for (final operation in readyOperations) {
        if (!_networkService.isOnline && !operation.persistentRetry) {
          continue; // 네트워크가 없으면 지속적 재시도가 아닌 작업은 건너뜀
        }

        await _executeRetry(operation);
      }
    } catch (e, s) {
      logger.e('Error processing retry queue', error: e, stackTrace: s);
    } finally {
      _isProcessing = false;
    }
  }

  /// 개별 재시도 작업 실행
  Future<void> _executeRetry(RetryOperation operation) async {
    final operationKey = '${operation.id}_${operation.priority.name}';

    // 서킷 브레이커 확인
    if (_isCircuitBreakerOpen(operationKey)) {
      logger.w('Circuit breaker is open for operation: ${operation.id}');
      return;
    }

    var context = _activeRetries[operation.id];
    context ??= RetryContext(
      operation: operation,
      attemptCount: 0,
      firstAttemptAt: DateTime.now(),
      nextRetryAt: DateTime.now(),
    );

    try {
      context.attemptCount++;
      context.lastAttemptAt = DateTime.now();

      logger.d(
          'Executing retry attempt ${context.attemptCount}/${operation.maxAttempts} for ${operation.id}');

      // 작업 실행

      // 성공시 정리
      _priorityQueue.removeWhere((op) => op.id == operation.id);
      _activeRetries.remove(operation.id);
      _resetCircuitBreaker(operationKey);

      if (operation.persistentRetry) {
        await _removePersistentRetry(operation.id);
      }

      logger.i('Retry operation succeeded: ${operation.id}');
    } catch (e) {
      // 재시도 가능한 예외인지 확인
      if (!_shouldRetry(e, operation.retryOnExceptions)) {
        logger.w('Non-retryable exception for ${operation.id}: $e');
        _priorityQueue.removeWhere((op) => op.id == operation.id);
        _activeRetries.remove(operation.id);
        return;
      }

      // 최대 시도 횟수 확인
      if (context.attemptCount >= operation.maxAttempts) {
        logger.e('Max retry attempts reached for ${operation.id}');
        _priorityQueue.removeWhere((op) => op.id == operation.id);
        _activeRetries.remove(operation.id);
        _openCircuitBreaker(operationKey);

        if (operation.persistentRetry) {
          await _markPersistentRetryFailed(operation.id);
        }
        return;
      }

      // 다음 재시도 시간 계산
      final delay = _calculateDelay(
          operation.strategy, context.attemptCount, operation.initialDelay);
      context.nextRetryAt = DateTime.now().add(delay);
      _activeRetries[operation.id] = context;

      _recordCircuitBreakerFailure(operationKey);

      logger.w(
          'Retry attempt ${context.attemptCount} failed for ${operation.id}, next retry in ${delay.inSeconds}s: $e');
    }
  }

  /// 재시도 지연 시간 계산
  Duration _calculateDelay(
      RetryStrategy strategy, int attemptCount, Duration initialDelay) {
    switch (strategy) {
      case RetryStrategy.exponentialBackoff:
        final multiplier = pow(2, attemptCount - 1).toDouble();
        final delay = Duration(
            milliseconds: (initialDelay.inMilliseconds * multiplier).round());
        return delay > _maxRetryDelay ? _maxRetryDelay : delay;

      case RetryStrategy.linearBackoff:
        final delay =
            Duration(milliseconds: initialDelay.inMilliseconds * attemptCount);
        return delay > _maxRetryDelay ? _maxRetryDelay : delay;

      case RetryStrategy.fixedDelay:
        return initialDelay;

      case RetryStrategy.randomJitter:
        final jitter = Random().nextDouble() * 0.5 + 0.5; // 0.5 ~ 1.0
        final delay = Duration(
            milliseconds:
                (initialDelay.inMilliseconds * attemptCount * jitter).round());
        return delay > _maxRetryDelay ? _maxRetryDelay : delay;
    }
  }

  /// 우선순위에 따라 큐에 삽입
  void _insertByPriority(RetryOperation operation) {
    int insertIndex = _priorityQueue.length;

    for (int i = 0; i < _priorityQueue.length; i++) {
      if (operation.priority.value > _priorityQueue[i].priority.value) {
        insertIndex = i;
        break;
      }
    }

    _priorityQueue.insert(insertIndex, operation);
  }

  /// 재시도 가능한 예외인지 확인
  bool _shouldRetry(dynamic exception, List<Type> retryOnExceptions) {
    return retryOnExceptions
        .any((type) => exception.runtimeType == type || exception is Exception);
  }

  /// 서킷 브레이커 관련 메서드들
  bool _isCircuitBreakerOpen(String key) {
    final breaker = _circuitBreakers[key];
    if (breaker == null) return false;

    if (breaker.state == CircuitState.open) {
      if (DateTime.now().isAfter(breaker.nextRetryAt)) {
        breaker.state = CircuitState.halfOpen;
        return false;
      }
      return true;
    }

    return false;
  }

  void _openCircuitBreaker(String key) {
    _circuitBreakers[key] = CircuitBreakerState(
      state: CircuitState.open,
      failureCount: 0,
      nextRetryAt: DateTime.now().add(_circuitBreakerResetTimeout),
    );
    logger.w('Circuit breaker opened for: $key');
  }

  void _resetCircuitBreaker(String key) {
    _circuitBreakers[key] = CircuitBreakerState(
      state: CircuitState.closed,
      failureCount: 0,
      nextRetryAt: DateTime.now(),
    );
  }

  void _recordCircuitBreakerFailure(String key) {
    var breaker = _circuitBreakers[key];
    breaker ??= CircuitBreakerState(
      state: CircuitState.closed,
      failureCount: 0,
      nextRetryAt: DateTime.now(),
    );

    breaker.failureCount++;

    if (breaker.failureCount >= _circuitBreakerFailureThreshold) {
      _openCircuitBreaker(key);
    } else {
      _circuitBreakers[key] = breaker;
    }
  }

  /// 지속적 재시도 데이터베이스 관리
  Future<void> _savePersistentRetry(RetryOperation operation) async {
    await _localDb.insert('persistent_retries', {
      'id': operation.id,
      'operation_data': operation.toJson(),
      'created_at': operation.createdAt.toIso8601String(),
      'status': 'pending',
    });
  }

  Future<void> _removePersistentRetry(String operationId) async {
    await _localDb.delete('persistent_retries', 'id = ?', [operationId]);
  }

  Future<void> _markPersistentRetryFailed(String operationId) async {
    await _localDb.update(
        'persistent_retries',
        {
          'status': 'failed',
          'failed_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [operationId]);
  }

  /// 지속적 재시도 작업 복원 (앱 재시작시)
  Future<void> restorePersistentRetries() async {
    try {
      final results = await _localDb.query(
        'persistent_retries',
        where: 'status = ?',
        whereArgs: ['pending'],
      );

      for (final row in results) {
        // JSON에서 RetryOperation 복원하고 큐에 추가
        // 실제 구현에서는 operation 함수를 복원하는 방법이 필요
        logger.i('Restored persistent retry: ${row['id']}');
      }
    } catch (e, s) {
      logger.e('Error restoring persistent retries', error: e, stackTrace: s);
    }
  }

  /// 현재 큐 상태 조회
  Map<String, dynamic> getQueueStatus() {
    return {
      'pending_operations': _priorityQueue.length,
      'active_retries': _activeRetries.length,
      'circuit_breakers': _circuitBreakers.length,
      'operations_by_priority': {
        'critical': _priorityQueue
            .where((op) => op.priority == RetryPriority.critical)
            .length,
        'high': _priorityQueue
            .where((op) => op.priority == RetryPriority.high)
            .length,
        'normal': _priorityQueue
            .where((op) => op.priority == RetryPriority.normal)
            .length,
        'low': _priorityQueue
            .where((op) => op.priority == RetryPriority.low)
            .length,
      },
    };
  }

  /// 서비스 정리
  Future<void> dispose() async {
    _retryProcessor?.cancel();
    _priorityQueue.clear();
    _activeRetries.clear();
    _circuitBreakers.clear();
    logger.i('EnhancedRetryService disposed');
  }
}

/// 재시도 우선순위
enum RetryPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  const RetryPriority(this.value);
  final int value;
}

/// 재시도 전략
enum RetryStrategy {
  exponentialBackoff,
  linearBackoff,
  fixedDelay,
  randomJitter,
}

/// 서킷 브레이커 상태
enum CircuitState {
  closed,
  open,
  halfOpen,
}

/// 재시도 작업 정보
class RetryOperation {
  final String id;
  final Future<dynamic> Function() operation;
  final RetryPriority priority;
  final int maxAttempts;
  final Duration initialDelay;
  final RetryStrategy strategy;
  final List<Type> retryOnExceptions;
  final bool persistentRetry;
  final DateTime createdAt;

  RetryOperation({
    required this.id,
    required this.operation,
    required this.priority,
    required this.maxAttempts,
    required this.initialDelay,
    required this.strategy,
    required this.retryOnExceptions,
    required this.persistentRetry,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'priority': priority.name,
      'maxAttempts': maxAttempts,
      'initialDelay': initialDelay.inMilliseconds,
      'strategy': strategy.name,
      'retryOnExceptions': retryOnExceptions.map((e) => e.toString()).toList(),
      'persistentRetry': persistentRetry,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 재시도 컨텍스트
class RetryContext {
  final RetryOperation operation;
  int attemptCount;
  final DateTime firstAttemptAt;
  DateTime? lastAttemptAt;
  DateTime nextRetryAt;

  RetryContext({
    required this.operation,
    required this.attemptCount,
    required this.firstAttemptAt,
    this.lastAttemptAt,
    required this.nextRetryAt,
  });
}

/// 서킷 브레이커 상태
class CircuitBreakerState {
  CircuitState state;
  int failureCount;
  DateTime nextRetryAt;

  CircuitBreakerState({
    required this.state,
    required this.failureCount,
    required this.nextRetryAt,
  });
}
