import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 낙관적 업데이트의 타입을 정의하는 열거형
enum OptimisticUpdateType {
  create,
  update,
  delete,
}

/// 낙관적 업데이트 작업을 나타내는 클래스
class OptimisticOperation {
  final String id;
  final OptimisticUpdateType type;
  final String resourceType;
  final String resourceId;
  final Map<String, dynamic> originalData;
  final Map<String, dynamic> optimisticData;
  final DateTime timestamp;
  final Future<Map<String, dynamic>> Function() operation;
  final VoidCallback? onSuccess;
  final Function(dynamic error)? onError;

  OptimisticOperation({
    required this.id,
    required this.type,
    required this.resourceType,
    required this.resourceId,
    required this.originalData,
    required this.optimisticData,
    required this.operation,
    this.onSuccess,
    this.onError,
  }) : timestamp = DateTime.now();

  /// 작업이 타임아웃되었는지 확인
  bool get isTimeout =>
      DateTime.now().difference(timestamp) > const Duration(seconds: 30);
}

/// 낙관적 업데이트를 관리하는 서비스
class OptimisticUpdateService {
  static final OptimisticUpdateService _instance =
      OptimisticUpdateService._internal();
  factory OptimisticUpdateService() => _instance;
  OptimisticUpdateService._internal();

  final Map<String, OptimisticOperation> _pendingOperations = {};
  final Map<String, List<OptimisticOperation>> _resourceOperations = {};
  final Random _random = Random();

  /// 현재 대기 중인 작업 수
  int get pendingCount => _pendingOperations.length;

  /// 특정 리소스에 대한 대기 중인 작업들
  List<OptimisticOperation> getResourceOperations(String resourceId) {
    return _resourceOperations[resourceId] ?? [];
  }

  /// 고유 ID 생성
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = _random.nextInt(999999);
    final input = '$timestamp$randomValue';
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// 낙관적 업데이트 실행
  /// 
  /// [type] 업데이트 타입
  /// [resourceType] 리소스 타입 (예: 'post', 'comment', 'vote')
  /// [resourceId] 리소스 ID
  /// [originalData] 원본 데이터
  /// [optimisticData] 낙관적 업데이트된 데이터
  /// [operation] 실제 서버 작업
  /// [onSuccess] 성공 콜백
  /// [onError] 에러 콜백
  Future<String> executeOptimisticUpdate({
    required OptimisticUpdateType type,
    required String resourceType,
    required String resourceId,
    required Map<String, dynamic> originalData,
    required Map<String, dynamic> optimisticData,
    required Future<Map<String, dynamic>> Function() operation,
    VoidCallback? onSuccess,
    Function(dynamic error)? onError,
  }) async {
    final operationId = _generateId();

    final optimisticOp = OptimisticOperation(
      id: operationId,
      type: type,
      resourceType: resourceType,
      resourceId: resourceId,
      originalData: Map.from(originalData),
      optimisticData: Map.from(optimisticData),
      operation: operation,
      onSuccess: onSuccess,
      onError: onError,
    );

    // 작업 등록
    _pendingOperations[operationId] = optimisticOp;
    _resourceOperations.putIfAbsent(resourceId, () => []).add(optimisticOp);

    logger.d(
        '낙관적 업데이트 시작: $operationId ($resourceType:$resourceId)');

    // 백그라운드에서 실제 작업 실행
    unawaited(_executeOperation(optimisticOp));

    return operationId;
  }

  /// 실제 서버 작업 실행
  Future<void> _executeOperation(OptimisticOperation op) async {
    try {
      logger.d('서버 작업 실행: ${op.id}');

      // 서버 작업 실행
      final result = await op.operation();

      // 성공 처리
      _handleSuccess(op, result);
    } catch (e, stackTrace) {
      logger.e('서버 작업 실패: ${op.id}', error: e, stackTrace: stackTrace);

      // 에러 처리
      _handleError(op, e);
    }
  }

  /// 성공 처리
  void _handleSuccess(OptimisticOperation op, Map<String, dynamic> result) {
    logger.d('낙관적 업데이트 성공: ${op.id}');

    // 대기 중인 작업에서 제거
    _removeOperation(op);

    // 성공 콜백 실행
    op.onSuccess?.call();

    // 성공 이벤트 브로드캐스트
    _broadcastSuccess(op, result);
  }

  /// 에러 처리 및 롤백
  void _handleError(OptimisticOperation op, dynamic error) {
    logger.e('낙관적 업데이트 실패, 롤백 수행: ${op.id}');

    // 대기 중인 작업에서 제거
    _removeOperation(op);

    // 에러 콜백 실행
    op.onError?.call(error);

    // 롤백 이벤트 브로드캐스트
    _broadcastRollback(op, error);
  }

  /// 작업 제거
  void _removeOperation(OptimisticOperation op) {
    _pendingOperations.remove(op.id);
    _resourceOperations[op.resourceId]?.remove(op);
    if (_resourceOperations[op.resourceId]?.isEmpty == true) {
      _resourceOperations.remove(op.resourceId);
    }
  }

  /// 수동 롤백
  Future<void> rollbackOperation(String operationId) async {
    final operation = _pendingOperations[operationId];
    if (operation == null) {
      logger.w('롤백할 작업을 찾을 수 없습니다: $operationId');
      return;
    }

    logger.i('수동 롤백 수행: $operationId');
    _handleError(operation, Exception('Manual rollback'));
  }

  /// 특정 리소스의 모든 작업 롤백
  Future<void> rollbackResourceOperations(String resourceId) async {
    final operations = List<OptimisticOperation>.from(
        _resourceOperations[resourceId] ?? []);

    logger.i('리소스 작업 모두 롤백: $resourceId (${operations.length}개)');

    for (final operation in operations) {
      _handleError(operation, Exception('Resource rollback'));
    }
  }

  /// 타임아웃된 작업들 정리
  void cleanupTimeoutOperations() {
    final timeoutOperations = _pendingOperations.values
        .where((op) => op.isTimeout)
        .toList();

    for (final operation in timeoutOperations) {
      logger.w('타임아웃된 작업 롤백: ${operation.id}');
      _handleError(operation, TimeoutException('Operation timeout'));
    }
  }

  /// 모든 대기 중인 작업 취소
  Future<void> cancelAllOperations() async {
    final operations = List<OptimisticOperation>.from(_pendingOperations.values);

    logger.i('모든 낙관적 업데이트 취소: ${operations.length}개');

    for (final operation in operations) {
      _handleError(operation, Exception('Operation cancelled'));
    }
  }

  /// 성공 이벤트 브로드캐스트
  void _broadcastSuccess(OptimisticOperation op, Map<String, dynamic> result) {
    _successStreamController.add(OptimisticUpdateResult(
      operationId: op.id,
      resourceType: op.resourceType,
      resourceId: op.resourceId,
      type: op.type,
      isSuccess: true,
      data: result,
    ));
  }

  /// 롤백 이벤트 브로드캐스트
  void _broadcastRollback(OptimisticOperation op, dynamic error) {
    _rollbackStreamController.add(OptimisticUpdateResult(
      operationId: op.id,
      resourceType: op.resourceType,
      resourceId: op.resourceId,
      type: op.type,
      isSuccess: false,
      error: error,
      originalData: op.originalData,
    ));
  }

  /// 성공 이벤트 스트림
  final StreamController<OptimisticUpdateResult> _successStreamController =
      StreamController<OptimisticUpdateResult>.broadcast();

  Stream<OptimisticUpdateResult> get successStream =>
      _successStreamController.stream;

  /// 롤백 이벤트 스트림
  final StreamController<OptimisticUpdateResult> _rollbackStreamController =
      StreamController<OptimisticUpdateResult>.broadcast();

  Stream<OptimisticUpdateResult> get rollbackStream =>
      _rollbackStreamController.stream;

  /// 서비스 정리
  void dispose() {
    logger.i('OptimisticUpdateService 정리');

    // 모든 작업 취소
    cancelAllOperations();

    // 스트림 컨트롤러 닫기
    _successStreamController.close();
    _rollbackStreamController.close();
  }
}

/// 낙관적 업데이트 결과를 나타내는 클래스
class OptimisticUpdateResult {
  final String operationId;
  final String resourceType;
  final String resourceId;
  final OptimisticUpdateType type;
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? originalData;
  final dynamic error;

  OptimisticUpdateResult({
    required this.operationId,
    required this.resourceType,
    required this.resourceId,
    required this.type,
    required this.isSuccess,
    this.data,
    this.originalData,
    this.error,
  });

  @override
  String toString() {
    return 'OptimisticUpdateResult('
        'operationId: $operationId, '
        'resourceType: $resourceType, '
        'resourceId: $resourceId, '
        'type: $type, '
        'isSuccess: $isSuccess'
        ')';
  }
}

/// 충돌 해결 전략
enum ConflictResolutionStrategy {
  clientWins,    // 클라이언트 데이터 우선
  serverWins,    // 서버 데이터 우선
  merge,         // 데이터 병합
  manual,        // 수동 해결
}

/// 충돌 해결기
class ConflictResolver {
  /// 충돌 해결
  static Map<String, dynamic> resolveConflict(
    Map<String, dynamic> clientData,
    Map<String, dynamic> serverData,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.clientWins:
        return clientData;
      case ConflictResolutionStrategy.serverWins:
        return serverData;
      case ConflictResolutionStrategy.merge:
        return _mergeData(clientData, serverData);
      case ConflictResolutionStrategy.manual:
        throw Exception('Manual conflict resolution required');
    }
  }

  /// 데이터 병합
  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> clientData,
    Map<String, dynamic> serverData,
  ) {
    final merged = Map<String, dynamic>.from(serverData);

    // 클라이언트에서 수정된 필드들만 덮어쓰기
    for (final entry in clientData.entries) {
      if (entry.value != null) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }
}

/// 낙관적 업데이트 유틸리티 함수들
class OptimisticUtils {
  /// 임시 ID 생성
  static String generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 데이터가 낙관적 업데이트인지 확인
  static bool isOptimistic(Map<String, dynamic> data) {
    return data['is_optimistic'] == true ||
        data['id']?.toString().startsWith('temp_') == true;
  }

  /// 낙관적 업데이트 마킹
  static Map<String, dynamic> markAsOptimistic(Map<String, dynamic> data) {
    return {
      ...data,
      'is_optimistic': true,
      'optimistic_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 낙관적 업데이트 마킹 해제
  static Map<String, dynamic> unmarkOptimistic(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);
    cleaned.remove('is_optimistic');
    cleaned.remove('optimistic_timestamp');
    return cleaned;
  }
}