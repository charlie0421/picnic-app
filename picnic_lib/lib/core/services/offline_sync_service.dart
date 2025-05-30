import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart'
    show EnhancedNetworkService, NetworkInfo;
import 'package:picnic_lib/core/services/enhanced_retry_service.dart';
import 'package:picnic_lib/core/services/conflict_resolution_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

/// 오프라인 데이터 동기화 서비스
/// 로컬 데이터베이스와 원격 서버 간의 양방향 동기화를 관리합니다.
class OfflineSyncService {
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _maxRetryAttempts = 3;

  static OfflineSyncService? _instance;
  static OfflineSyncService get instance =>
      _instance ??= OfflineSyncService._();
  OfflineSyncService._();

  final OfflineDatabaseService _localDb = OfflineDatabaseService.instance;
  final EnhancedNetworkService _networkService = EnhancedNetworkService();
  final EnhancedRetryService _retryService = EnhancedRetryService.instance;
  final SupabaseClient _supabase = supabase;
  final ConflictResolutionService _conflictResolutionService =
      ConflictResolutionService.instance;

  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription? _networkSubscription;

  /// 동기화 상태 스트림
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// 동기화 서비스 초기화
  Future<void> initialize() async {
    try {
      logger.i('Initializing OfflineSyncService...');

      // EnhancedRetryService 초기화
      await _retryService.initialize();

      // ConflictResolutionService 초기화
      await _conflictResolutionService.initialize();

      // 지속적 재시도 작업 복원
      await _retryService.restorePersistentRetries();

      // 네트워크 상태 변화 감지
      _networkSubscription = _networkService.networkStatusStream.listen(
        _onNetworkStatusChanged,
        onError: (error) {
          logger.e('Network status monitoring error', error: error);
        },
      );

      // 주기적 동기화 시작
      _startPeriodicSync();

      logger.i('OfflineSyncService initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize OfflineSyncService',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 네트워크 상태 변화 처리
  void _onNetworkStatusChanged(NetworkInfo networkInfo) {
    if (networkInfo.isOnline && !_isSyncing) {
      logger.i('Network connection restored, starting sync...');
      _triggerSync();
    }
  }

  /// 주기적 동기화 시작
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_networkService.isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  /// 동기화 트리거
  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      _syncStatusController.add(SyncStatus.syncing);

      await _performSync();

      _syncStatusController.add(SyncStatus.completed);
      logger.i('Sync completed successfully');
    } catch (e, s) {
      logger.e('Sync failed', error: e, stackTrace: s);
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// 실제 동기화 수행
  Future<void> _performSync() async {
    // 1. 로컬 변경사항을 원격으로 업로드
    await _uploadLocalChanges();

    // 2. 원격 변경사항을 로컬로 다운로드
    await _downloadRemoteChanges();
  }

  /// 로컬 변경사항을 원격으로 업로드
  Future<void> _uploadLocalChanges() async {
    final syncQueue = await _localDb.getSyncQueue();

    for (final syncItem in syncQueue) {
      final operationId =
          'sync_${syncItem['id']}_${syncItem['table_name']}_${syncItem['operation']}';

      // EnhancedRetryService를 사용하여 재시도 스케줄링
      await _retryService.scheduleRetry(
        operationId: operationId,
        operation: () => _processSyncItem(syncItem),
        priority: _getSyncPriority(syncItem['table_name']),
        maxAttempts: _maxRetryAttempts,
        strategy: RetryStrategy.exponentialBackoff,
        retryOnExceptions: [
          PostgrestException,
          SocketException,
          TimeoutException
        ],
        persistentRetry: true,
      );

      // 성공적으로 스케줄링되면 기존 큐에서 제거
      await _localDb.removeFromSyncQueue(syncItem['id']);
    }
  }

  /// 동기화 우선순위 결정
  RetryPriority _getSyncPriority(String tableName) {
    switch (tableName) {
      case 'user_profiles':
        return RetryPriority.high;
      case 'user_votes':
        return RetryPriority.high;
      case 'votes':
        return RetryPriority.normal;
      case 'galleries':
        return RetryPriority.normal;
      default:
        return RetryPriority.low;
    }
  }

  /// 개별 동기화 항목 처리
  Future<void> _processSyncItem(Map<String, dynamic> syncItem) async {
    final tableName = syncItem['table_name'];
    final recordId = syncItem['record_id'];
    final operation = syncItem['operation'];
    final data = syncItem['data'] != null
        ? jsonDecode(syncItem['data']) as Map<String, dynamic>
        : null;

    // 직접적인 Supabase 호출 (재시도는 EnhancedRetryService가 처리)
    switch (operation) {
      case 'INSERT':
        await _supabase.from(tableName).insert(data!);
        break;
      case 'UPDATE':
        await _supabase.from(tableName).update(data!).eq('id', recordId);
        break;
      case 'DELETE':
        await _supabase.from(tableName).delete().eq('id', recordId);
        break;
      default:
        throw Exception('Unknown operation: $operation');
    }

    // 성공시 로컬 레코드를 clean으로 표시
    if (operation != 'DELETE') {
      await _localDb.markAsClean(tableName, recordId);
    }
  }

  /// 원격 변경사항을 로컬로 다운로드
  Future<void> _downloadRemoteChanges() async {
    // 각 테이블별로 최신 데이터 확인 및 업데이트
    final tables = ['user_profiles', 'votes', 'galleries', 'popups'];

    for (final table in tables) {
      try {
        await _syncTableFromRemote(table);
      } catch (e) {
        logger.e('Failed to sync table: $table', error: e);
      }
    }
  }

  /// 특정 테이블의 원격 데이터 동기화
  Future<void> _syncTableFromRemote(String tableName) async {
    // 로컬의 마지막 동기화 시간 확인
    final lastSync = await _getLastSyncTime(tableName);

    // 원격에서 변경된 데이터 가져오기
    var query = _supabase.from(tableName).select();

    if (lastSync != null) {
      query = query.gt('updated_at', lastSync.toIso8601String());
    }

    final remoteData = await query;

    if (remoteData.isNotEmpty) {
      // 로컬 데이터베이스 업데이트 (충돌 해결 포함)
      await _localDb.transaction((txn) async {
        for (final remoteItem in remoteData) {
          await _syncSingleRecord(txn, tableName, remoteItem);
        }
      });

      logger.d('Synced ${remoteData.length} records for table: $tableName');
    }
  }

  /// 개별 레코드 동기화 (충돌 해결 포함)
  Future<void> _syncSingleRecord(Transaction txn, String tableName,
      Map<String, dynamic> remoteItem) async {
    final recordId = remoteItem['id'].toString();

    // 로컬 데이터 확인
    final localResults = await txn.query(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
    );

    if (localResults.isEmpty) {
      // 새 레코드 - 직접 삽입
      remoteItem['last_sync'] = DateTime.now().toIso8601String();
      remoteItem['is_dirty'] = 0;

      await txn.insert(
        tableName,
        remoteItem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // 기존 레코드 - 충돌 확인 및 해결
      final localItem = localResults.first;

      // 더티 플래그 확인 (로컬 변경사항이 있는 경우)
      if (localItem['is_dirty'] == 1) {
        logger.i('Conflict detected for $tableName:$recordId');

        try {
          // 충돌 해결
          final resolution = await _conflictResolutionService.resolveConflict(
            tableName: tableName,
            recordId: recordId,
            localData: Map<String, dynamic>.from(localItem),
            remoteData: remoteItem,
          );

          if (resolution.success) {
            // 해결된 데이터로 업데이트
            final resolvedData =
                Map<String, dynamic>.from(resolution.resolvedData);
            resolvedData['last_sync'] = DateTime.now().toIso8601String();
            resolvedData['is_dirty'] = 0;

            await txn.update(
              tableName,
              resolvedData,
              where: 'id = ?',
              whereArgs: [recordId],
            );

            logger.i(
                'Conflict resolved for $tableName:$recordId using ${resolution.strategy.name}');
          } else {
            logger.e(
                'Failed to resolve conflict for $tableName:$recordId: ${resolution.error}');

            // 해결 실패시 원격 데이터로 덮어쓰기 (fallback)
            remoteItem['last_sync'] = DateTime.now().toIso8601String();
            remoteItem['is_dirty'] = 0;

            await txn.update(
              tableName,
              remoteItem,
              where: 'id = ?',
              whereArgs: [recordId],
            );
          }
        } catch (e) {
          logger.e('Error during conflict resolution for $tableName:$recordId',
              error: e);

          // 에러 발생시 원격 데이터로 덮어쓰기 (fallback)
          remoteItem['last_sync'] = DateTime.now().toIso8601String();
          remoteItem['is_dirty'] = 0;

          await txn.update(
            tableName,
            remoteItem,
            where: 'id = ?',
            whereArgs: [recordId],
          );
        }
      } else {
        // 로컬 변경사항이 없는 경우 - 직접 업데이트
        remoteItem['last_sync'] = DateTime.now().toIso8601String();
        remoteItem['is_dirty'] = 0;

        await txn.update(
          tableName,
          remoteItem,
          where: 'id = ?',
          whereArgs: [recordId],
        );
      }
    }
  }

  /// 테이블의 마지막 동기화 시간 조회
  Future<DateTime?> _getLastSyncTime(String tableName) async {
    try {
      final results = await _localDb.rawQuery(
        'SELECT MAX(last_sync) as last_sync FROM $tableName WHERE last_sync IS NOT NULL',
      );

      if (results.isNotEmpty && results.first['last_sync'] != null) {
        return DateTime.parse(results.first['last_sync']);
      }
    } catch (e) {
      logger.e('Error getting last sync time for $tableName', error: e);
    }

    return null;
  }

  /// 수동 동기화 트리거
  Future<void> forcSync() async {
    if (!_networkService.isOnline) {
      throw Exception('Cannot sync while offline');
    }

    await _triggerSync();
  }

  /// 특정 테이블 강제 동기화
  Future<void> forceSyncTable(String tableName) async {
    if (!_networkService.isOnline) {
      throw Exception('Cannot sync while offline');
    }

    try {
      _syncStatusController.add(SyncStatus.syncing);
      await _syncTableFromRemote(tableName);
      _syncStatusController.add(SyncStatus.completed);
    } catch (e, s) {
      logger.e('Failed to force sync table: $tableName',
          error: e, stackTrace: s);
      _syncStatusController.add(SyncStatus.failed);
      rethrow;
    }
  }

  /// 동기화 대기 중인 항목 수 조회
  Future<int> getPendingSyncCount() async {
    final syncQueue = await _localDb.getSyncQueue();
    return syncQueue.length;
  }

  /// 서비스 정리
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _networkSubscription?.cancel();
    await _syncStatusController.close();
    logger.i('OfflineSyncService disposed');
  }
}

/// 동기화 상태
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}
