import 'dart:async';
import 'dart:convert';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 데이터 동기화 충돌 해결 서비스
/// 로컬과 원격 데이터 간의 충돌을 감지하고 해결하는 다양한 전략을 제공합니다.
class ConflictResolutionService {
  static ConflictResolutionService? _instance;
  static ConflictResolutionService get instance => _instance ??= ConflictResolutionService._();
  ConflictResolutionService._();

  final OfflineDatabaseService _localDb = OfflineDatabaseService.instance;

  // 테이블별 기본 충돌 해결 전략
  final Map<String, ConflictResolutionStrategy> _defaultStrategies = {
    'user_profiles': ConflictResolutionStrategy.lastWriteWins,
    'votes': ConflictResolutionStrategy.remoteWins,
    'user_votes': ConflictResolutionStrategy.localWins,
    'galleries': ConflictResolutionStrategy.lastWriteWins,
  };

  // 필드별 충돌 해결 전략
  final Map<String, Map<String, ConflictResolutionStrategy>> _fieldStrategies = {
    'user_profiles': {
      'star_candy': ConflictResolutionStrategy.merge,
      'avatar_url': ConflictResolutionStrategy.lastWriteWins,
      'nickname': ConflictResolutionStrategy.manualReview,
    },
    'votes': {
      'vote_count': ConflictResolutionStrategy.merge,
      'status': ConflictResolutionStrategy.remoteWins,
    },
  };

  // 수동 리뷰가 필요한 충돌 목록
  final List<ConflictRecord> _pendingManualReview = [];

  /// 충돌 해결 서비스 초기화
  Future<void> initialize() async {
    try {
      logger.i('Initializing ConflictResolutionService...');
      
      // 이전에 해결되지 않은 충돌 복원
      await _restorePendingConflicts();
      
      logger.i('ConflictResolutionService initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize ConflictResolutionService', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 충돌 감지 및 해결
  Future<ConflictResolutionResult> resolveConflict({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictResolutionStrategy? overrideStrategy,
  }) async {
    try {
      logger.d('Resolving conflict for $tableName:$recordId');

      // 충돌 감지
      final conflicts = _detectConflicts(localData, remoteData);
      if (conflicts.isEmpty) {
        return ConflictResolutionResult(
          success: true,
          resolvedData: remoteData,
          conflictDetails: [],
          strategy: ConflictResolutionStrategy.noConflict,
        );
      }

      logger.i('Detected ${conflicts.length} conflicts for $tableName:$recordId');

      // 충돌 해결 전략 결정
      final strategy = overrideStrategy ?? 
                     _getTableStrategy(tableName) ?? 
                     ConflictResolutionStrategy.lastWriteWins;

      // 전략에 따른 충돌 해결
      final result = await _applyResolutionStrategy(
        tableName: tableName,
        recordId: recordId,
        localData: localData,
        remoteData: remoteData,
        conflicts: conflicts,
        strategy: strategy,
      );

      // 충돌 해결 기록 저장
      await _recordConflictResolution(
        tableName: tableName,
        recordId: recordId,
        conflicts: conflicts,
        result: result,
      );

      return result;
    } catch (e, s) {
      logger.e('Error resolving conflict', error: e, stackTrace: s);
      return ConflictResolutionResult(
        success: false,
        resolvedData: localData,
        conflictDetails: [],
        strategy: ConflictResolutionStrategy.localWins,
        error: e.toString(),
      );
    }
  }

  /// 충돌 감지
  List<FieldConflict> _detectConflicts(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final conflicts = <FieldConflict>[];

    for (final key in localData.keys) {
      if (!remoteData.containsKey(key)) continue;

      final localValue = localData[key];
      final remoteValue = remoteData[key];

      // null 값 처리
      if (localValue == null && remoteValue == null) continue;
      if (localValue == null || remoteValue == null) {
        conflicts.add(FieldConflict(
          fieldName: key,
          localValue: localValue,
          remoteValue: remoteValue,
          conflictType: ConflictType.nullValueConflict,
        ));
        continue;
      }

      // 값 비교
      if (localValue != remoteValue) {
        conflicts.add(FieldConflict(
          fieldName: key,
          localValue: localValue,
          remoteValue: remoteValue,
          conflictType: _determineConflictType(key, localValue, remoteValue),
        ));
      }
    }

    return conflicts;
  }

  /// 충돌 타입 결정
  ConflictType _determineConflictType(String fieldName, dynamic localValue, dynamic remoteValue) {
    // 숫자 필드인 경우
    if (localValue is num && remoteValue is num) {
      return ConflictType.numericConflict;
    }

    // 날짜 필드인 경우
    if (fieldName.contains('_at') || fieldName.contains('date')) {
      return ConflictType.timestampConflict;
    }

    // 텍스트 필드인 경우
    if (localValue is String && remoteValue is String) {
      return ConflictType.textConflict;
    }

    return ConflictType.dataTypeConflict;
  }

  /// 테이블의 기본 해결 전략 조회
  ConflictResolutionStrategy? _getTableStrategy(String tableName) {
    return _defaultStrategies[tableName];
  }

  /// 필드별 해결 전략 조회
  ConflictResolutionStrategy? _getFieldStrategy(String tableName, String fieldName) {
    return _fieldStrategies[tableName]?[fieldName];
  }

  /// 해결 전략 적용
  Future<ConflictResolutionResult> _applyResolutionStrategy({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required List<FieldConflict> conflicts,
    required ConflictResolutionStrategy strategy,
  }) async {
    Map<String, dynamic> resolvedData = Map.from(remoteData);
    final List<FieldConflict> processedConflicts = [];

    for (final conflict in conflicts) {
      final fieldStrategy = _getFieldStrategy(tableName, conflict.fieldName) ?? strategy;
      
      final resolution = await _resolveFieldConflict(
        tableName: tableName,
        recordId: recordId,
        conflict: conflict,
        strategy: fieldStrategy,
        localData: localData,
        remoteData: remoteData,
      );

      if (resolution.needsManualReview) {
        await _addToManualReview(
          tableName: tableName,
          recordId: recordId,
          conflict: conflict,
          localData: localData,
          remoteData: remoteData,
        );
        processedConflicts.add(conflict.copyWith(requiresManualReview: true));
      } else {
        resolvedData[conflict.fieldName] = resolution.resolvedValue;
        processedConflicts.add(conflict.copyWith(resolvedValue: resolution.resolvedValue));
      }
    }

    return ConflictResolutionResult(
      success: true,
      resolvedData: resolvedData,
      conflictDetails: processedConflicts,
      strategy: strategy,
    );
  }

  /// 개별 필드 충돌 해결
  Future<FieldResolution> _resolveFieldConflict({
    required String tableName,
    required String recordId,
    required FieldConflict conflict,
    required ConflictResolutionStrategy strategy,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) async {
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return FieldResolution(resolvedValue: conflict.localValue);

      case ConflictResolutionStrategy.remoteWins:
        return FieldResolution(resolvedValue: conflict.remoteValue);

      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveByTimestamp(localData, remoteData, conflict);

      case ConflictResolutionStrategy.merge:
        return await _mergeBehavior(conflict);

      case ConflictResolutionStrategy.manualReview:
        return FieldResolution(needsManualReview: true);

      case ConflictResolutionStrategy.noConflict:
        return FieldResolution(resolvedValue: conflict.remoteValue);
    }
  }

  /// 타임스탬프 기반 해결
  FieldResolution _resolveByTimestamp(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    FieldConflict conflict,
  ) {
    try {
      final localUpdatedAt = DateTime.tryParse(localData['updated_at'] ?? '');
      final remoteUpdatedAt = DateTime.tryParse(remoteData['updated_at'] ?? '');

      if (localUpdatedAt == null || remoteUpdatedAt == null) {
        return FieldResolution(resolvedValue: conflict.remoteValue);
      }

      if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
        return FieldResolution(resolvedValue: conflict.localValue);
      } else {
        return FieldResolution(resolvedValue: conflict.remoteValue);
      }
    } catch (e) {
      logger.w('Error comparing timestamps, using remote value: $e');
      return FieldResolution(resolvedValue: conflict.remoteValue);
    }
  }

  /// 병합 동작
  Future<FieldResolution> _mergeBehavior(FieldConflict conflict) async {
    final localValue = conflict.localValue;
    final remoteValue = conflict.remoteValue;

    // 숫자 병합 (합계)
    if (localValue is num && remoteValue is num) {
      return FieldResolution(resolvedValue: localValue + remoteValue);
    }

    // 문자열 병합 (연결)
    if (localValue is String && remoteValue is String) {
      if (localValue.isEmpty) return FieldResolution(resolvedValue: remoteValue);
      if (remoteValue.isEmpty) return FieldResolution(resolvedValue: localValue);
      return FieldResolution(resolvedValue: '$localValue | $remoteValue');
    }

    // 리스트 병합
    if (localValue is List && remoteValue is List) {
      final merged = List.from(localValue);
      for (final item in remoteValue) {
        if (!merged.contains(item)) {
          merged.add(item);
        }
      }
      return FieldResolution(resolvedValue: merged);
    }

    // 기본적으로 원격 값 선택
    return FieldResolution(resolvedValue: remoteValue);
  }

  /// 수동 리뷰에 추가
  Future<void> _addToManualReview({
    required String tableName,
    required String recordId,
    required FieldConflict conflict,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) async {
    final conflictRecord = ConflictRecord(
      id: '${tableName}_${recordId}_${conflict.fieldName}_${DateTime.now().millisecondsSinceEpoch}',
      tableName: tableName,
      recordId: recordId,
      conflict: conflict,
      localData: localData,
      remoteData: remoteData,
      createdAt: DateTime.now(),
      status: ConflictStatus.pending,
    );

    _pendingManualReview.add(conflictRecord);

    // 데이터베이스에 저장
    await _localDb.insert('conflict_reviews', {
      'id': conflictRecord.id,
      'table_name': tableName,
      'record_id': recordId,
      'field_name': conflict.fieldName,
      'local_value': jsonEncode(conflict.localValue),
      'remote_value': jsonEncode(conflict.remoteValue),
      'local_data': jsonEncode(localData),
      'remote_data': jsonEncode(remoteData),
      'conflict_type': conflict.conflictType.name,
      'created_at': conflictRecord.createdAt.toIso8601String(),
      'status': conflictRecord.status.name,
    });

    logger.w('Conflict added to manual review: ${conflictRecord.id}');
  }

  /// 충돌 해결 기록 저장
  Future<void> _recordConflictResolution({
    required String tableName,
    required String recordId,
    required List<FieldConflict> conflicts,
    required ConflictResolutionResult result,
  }) async {
    await _localDb.insert('conflict_history', {
      'id': '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
      'table_name': tableName,
      'record_id': recordId,
      'conflicts_count': conflicts.length,
      'strategy_used': result.strategy.name,
      'resolution_data': jsonEncode(result.resolvedData),
      'success': result.success ? 1 : 0,
      'error_message': result.error,
      'resolved_at': DateTime.now().toIso8601String(),
    });
  }

  /// 이전 충돌 복원
  Future<void> _restorePendingConflicts() async {
    try {
      final results = await _localDb.query(
        'conflict_reviews',
        where: 'status = ?',
        whereArgs: ['pending'],
      );

      for (final row in results) {
        final conflictRecord = ConflictRecord(
          id: row['id'],
          tableName: row['table_name'],
          recordId: row['record_id'],
          conflict: FieldConflict(
            fieldName: row['field_name'],
            localValue: jsonDecode(row['local_value']),
            remoteValue: jsonDecode(row['remote_value']),
            conflictType: ConflictType.values.firstWhere(
              (e) => e.name == row['conflict_type'],
              orElse: () => ConflictType.dataTypeConflict,
            ),
          ),
          localData: jsonDecode(row['local_data']),
          remoteData: jsonDecode(row['remote_data']),
          createdAt: DateTime.parse(row['created_at']),
          status: ConflictStatus.values.firstWhere(
            (e) => e.name == row['status'],
            orElse: () => ConflictStatus.pending,
          ),
        );

        _pendingManualReview.add(conflictRecord);
      }

      logger.i('Restored ${_pendingManualReview.length} pending conflicts');
    } catch (e, s) {
      logger.e('Error restoring pending conflicts', error: e, stackTrace: s);
    }
  }

  /// 수동 리뷰 대기 중인 충돌 조회
  List<ConflictRecord> getPendingManualReviews() {
    return List.unmodifiable(_pendingManualReview);
  }

  /// 수동 충돌 해결
  Future<bool> resolveManualConflict({
    required String conflictId,
    required dynamic resolvedValue,
  }) async {
    try {
      final conflictIndex = _pendingManualReview.indexWhere((c) => c.id == conflictId);
      if (conflictIndex == -1) {
        logger.w('Conflict not found: $conflictId');
        return false;
      }

      
      // 데이터베이스 업데이트
      await _localDb.update('conflict_reviews', {
        'status': ConflictStatus.resolved.name,
        'resolved_value': jsonEncode(resolvedValue),
        'resolved_at': DateTime.now().toIso8601String(),
      }, 'id = ?', [conflictId]);

      // 메모리에서 제거
      _pendingManualReview.removeAt(conflictIndex);

      logger.i('Manual conflict resolved: $conflictId');
      return true;
    } catch (e, s) {
      logger.e('Error resolving manual conflict', error: e, stackTrace: s);
      return false;
    }
  }

  /// 테이블의 기본 전략 설정
  void setTableStrategy(String tableName, ConflictResolutionStrategy strategy) {
    _defaultStrategies[tableName] = strategy;
    logger.d('Set strategy for $tableName: ${strategy.name}');
  }

  /// 필드의 전략 설정
  void setFieldStrategy(String tableName, String fieldName, ConflictResolutionStrategy strategy) {
    _fieldStrategies[tableName] ??= {};
    _fieldStrategies[tableName]![fieldName] = strategy;
    logger.d('Set field strategy for $tableName.$fieldName: ${strategy.name}');
  }

  /// 서비스 정리
  Future<void> dispose() async {
    _pendingManualReview.clear();
    logger.i('ConflictResolutionService disposed');
  }
}

/// 충돌 해결 전략
enum ConflictResolutionStrategy {
  localWins,        // 로컬 데이터 우선
  remoteWins,       // 원격 데이터 우선
  lastWriteWins,    // 마지막 수정 시간 기준
  merge,            // 병합 (가능한 경우)
  manualReview,     // 수동 리뷰 필요
  noConflict,       // 충돌 없음
}

/// 충돌 타입
enum ConflictType {
  textConflict,
  numericConflict,
  timestampConflict,
  nullValueConflict,
  dataTypeConflict,
}

/// 충돌 상태
enum ConflictStatus {
  pending,
  resolved,
  dismissed,
}

/// 필드 충돌 정보
class FieldConflict {
  final String fieldName;
  final dynamic localValue;
  final dynamic remoteValue;
  final ConflictType conflictType;
  final dynamic resolvedValue;
  final bool requiresManualReview;

  FieldConflict({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
    required this.conflictType,
    this.resolvedValue,
    this.requiresManualReview = false,
  });

  FieldConflict copyWith({
    String? fieldName,
    dynamic localValue,
    dynamic remoteValue,
    ConflictType? conflictType,
    dynamic resolvedValue,
    bool? requiresManualReview,
  }) {
    return FieldConflict(
      fieldName: fieldName ?? this.fieldName,
      localValue: localValue ?? this.localValue,
      remoteValue: remoteValue ?? this.remoteValue,
      conflictType: conflictType ?? this.conflictType,
      resolvedValue: resolvedValue ?? this.resolvedValue,
      requiresManualReview: requiresManualReview ?? this.requiresManualReview,
    );
  }
}

/// 필드 해결 결과
class FieldResolution {
  final dynamic resolvedValue;
  final bool needsManualReview;

  FieldResolution({
    this.resolvedValue,
    this.needsManualReview = false,
  });
}

/// 충돌 해결 결과
class ConflictResolutionResult {
  final bool success;
  final Map<String, dynamic> resolvedData;
  final List<FieldConflict> conflictDetails;
  final ConflictResolutionStrategy strategy;
  final String? error;

  ConflictResolutionResult({
    required this.success,
    required this.resolvedData,
    required this.conflictDetails,
    required this.strategy,
    this.error,
  });
}

/// 충돌 기록
class ConflictRecord {
  final String id;
  final String tableName;
  final String recordId;
  final FieldConflict conflict;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime createdAt;
  final ConflictStatus status;

  ConflictRecord({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.conflict,
    required this.localData,
    required this.remoteData,
    required this.createdAt,
    required this.status,
  });
} 