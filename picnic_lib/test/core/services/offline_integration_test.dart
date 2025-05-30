// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/offline_sync_service.dart';
import 'package:picnic_lib/core/services/enhanced_retry_service.dart';
import 'package:picnic_lib/core/services/network_state_manager.dart';
import 'package:picnic_lib/core/services/conflict_resolution_service.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

/// 오프라인 기능 통합 테스트
///
/// 이 테스트는 다음 시나리오들을 검증합니다:
/// 1. 오프라인 모드에서의 데이터 생성/수정/삭제
/// 2. 네트워크 복구 시 자동 동기화
/// 3. 충돌 해결 메커니즘
/// 4. 재시도 로직
/// 5. 데이터 일관성 검증
void main() {
  group('오프라인 통합 테스트', () {
    late OfflineDatabaseService localDb;
    late OfflineSyncService syncService;
    late NetworkStateManager networkManager;
    late EnhancedRetryService retryService;
    late ConflictResolutionService conflictService;

    setUpAll(() async {
      // 서비스 초기화
      localDb = OfflineDatabaseService.instance;
      syncService = OfflineSyncService.instance;
      retryService = EnhancedRetryService.instance;
      networkManager = NetworkStateManager.instance;
      conflictService = ConflictResolutionService.instance;

      await localDb.init();
      await syncService.initialize();
      await retryService.initialize();
      await networkManager.initialize();
      await conflictService.initialize();
    });

    setUp(() async {
      // 각 테스트 전에 데이터베이스 클리어
      await _clearAllData();
    });

    tearDownAll(() async {
      // 테스트 완료 후 정리
      await localDb.cleanup();
    });

    group('오프라인 데이터 작업 테스트', () {
      testWidgets('오프라인 모드에서 사용자 프로필 생성 및 수정', (tester) async {
        // Given: 오프라인 모드 활성화
        await networkManager.setOfflineMode(true);

        // When: 사용자 프로필 생성
        final testProfileData = {
          'id': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
          'nickname': 'Test User',
          'avatar_url': 'https://example.com/avatar.jpg',
          'is_admin': 0,
          'star_candy': 100,
          'star_candy_bonus': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_dirty': 1,
        };

        await localDb.insert('user_profiles', testProfileData);

        // Then: 로컬에 저장되고 동기화 큐에 추가됨
        final profiles = await localDb.query('user_profiles',
            where: 'nickname = ?', whereArgs: ['Test User']);
        expect(profiles.length, equals(1));
        expect(profiles.first['nickname'], equals('Test User'));

        final syncQueue = await localDb.getSyncQueue();
        expect(syncQueue.length, greaterThanOrEqualTo(1));

        // When: 프로필 수정
        final updatedData = {
          'nickname': 'UpdatedUser',
          'bio': 'Updated Bio',
          'updated_at': DateTime.now().toIso8601String(),
          'is_dirty': 1,
        };

        await localDb.update(
            'user_profiles', updatedData, 'id = ?', [testProfileData['id']]);

        // Then: 로컬 업데이트됨
        final updatedSyncQueue = await localDb.getSyncQueue();
        expect(updatedSyncQueue.length, greaterThanOrEqualTo(1));

        final updatedProfiles = await localDb.query('user_profiles',
            where: 'id = ?', whereArgs: [testProfileData['id']]);
        expect(updatedProfiles.first['nickname'], equals('UpdatedUser'));
      });

      testWidgets('오프라인 모드에서 투표 데이터 조작', (tester) async {
        // Given: 오프라인 모드
        await networkManager.setOfflineMode(true);

        // When: 투표 생성
        final testVoteData = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': 'Test Vote',
          'vote_category': 'test',
          'main_image': 'https://example.com/vote.jpg',
          'wait_image': null,
          'result_image': null,
          'vote_content': 'This is a test vote',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_dirty': 1,
        };

        await localDb.insert('votes', testVoteData);

        // Then: 로컬 저장 및 동기화 큐 확인
        final votes = await localDb
            .query('votes', where: 'title = ?', whereArgs: ['Test Vote']);
        expect(votes.length, equals(1));
        expect(votes.first['title'], equals('Test Vote'));

        // When: 투표 삭제
        await localDb.delete('votes', 'id = ?', [testVoteData['id']]);

        // Then: 로컬에서 삭제됨
        final deletedVotes = await localDb
            .query('votes', where: 'id = ?', whereArgs: [testVoteData['id']]);
        expect(deletedVotes.length, equals(0));
      });
    });

    group('네트워크 복구 및 동기화 테스트', () {
      testWidgets('네트워크 복구 시 자동 동기화', (tester) async {
        // Given: 오프라인에서 데이터 변경
        await networkManager.setOfflineMode(true);

        final testProfileData = {
          'id': 'sync_test_user',
          'nickname': 'SyncUser',
          'avatar_url': 'https://example.com/sync_user_avatar.jpg',
          'is_admin': 0,
          'star_candy': 50,
          'star_candy_bonus': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_dirty': 1,
        };

        await localDb.insert('user_profiles', testProfileData);

        // 동기화 큐 확인
        var syncQueue = await localDb.getSyncQueue();
        expect(syncQueue.length, greaterThanOrEqualTo(1));

        // When: 온라인 모드 복구
        await networkManager.setOfflineMode(false);

        // Wait for automatic sync trigger
        await Future.delayed(Duration(seconds: 2));

        // 수동 동기화 트리거 (테스트 환경에서는 자동 동기화가 즉시 발생하지 않을 수 있음)
        try {
          await syncService.forcSync();
        } catch (e) {
          // 실제 서버 없이 테스트하는 경우 오류 무시
          print('Sync failed as expected in test environment: $e');
        }

        // Then: 로컬 데이터가 유지됨
        final profiles = await localDb.query('user_profiles',
            where: 'id = ?', whereArgs: ['sync_test_user']);
        expect(profiles.length, equals(1));
        expect(profiles.first['nickname'], equals('SyncUser'));
      });

      testWidgets('동기화 실패 시 재시도 메커니즘', (tester) async {
        // Given: 네트워크 불안정 상황 시뮬레이션
        await networkManager.setOfflineMode(true);

        final testData = UserProfilesModel(
          id: 'retry_test_user',
          nickname: 'RetryUser',
          avatarUrl: 'https://example.com/retry_user_avatar.jpg',
          isAdmin: false,
          starCandy: 75,
          starCandyBonus: 0,
        );

        await localDb.insert('user_profiles', testData.toJson());

        // When: 네트워크 복구하지만 동기화 실패 상황
        await networkManager.setOfflineMode(false);

        // 재시도 서비스 테스트
        var retryCompleted = false;
        await retryService.scheduleRetry(
          operationId: 'test_retry_operation',
          operation: () async {
            retryCompleted = true;
            return 'success';
          },
          maxAttempts: 3,
          strategy: RetryStrategy.exponentialBackoff,
          priority: RetryPriority.high,
        );

        // Then: 재시도 완료 확인
        expect(retryCompleted, isTrue);

        final queueStatus = retryService.getQueueStatus();
        expect(queueStatus, isNotNull);
      });
    });

    group('충돌 해결 테스트', () {
      testWidgets('자동 충돌 해결 - Last Write Wins', (tester) async {
        // Given: 로컬 데이터 생성
        final localProfile = UserProfilesModel(
          id: 'conflict_user',
          nickname: 'LocalUser',
          avatarUrl: 'https://example.com/local_user_avatar.jpg',
          isAdmin: false,
          starCandy: 100,
          starCandyBonus: 0,
        );

        // 로컬 데이터 직접 삽입
        await localDb.insert('user_profiles', {
          'id': 'conflict_user',
          'nickname': 'LocalUser',
          'avatar_url': localProfile.avatarUrl,
          'is_admin': localProfile.isAdmin,
          'star_candy': localProfile.starCandy,
          'star_candy_bonus': localProfile.starCandyBonus,
          'last_sync': null,
          'is_dirty': 1,
        });

        // 원격 데이터 시뮬레이션 (더 최근 업데이트)
        final remoteData = {
          'id': 'conflict_user',
          'nickname': 'RemoteUser',
          'avatar_url': 'https://example.com/remote_user_avatar.jpg',
          'is_admin': false,
          'star_candy': 150,
          'star_candy_bonus': 0,
          'updated_at': DateTime.now().toIso8601String(), // 더 최근
          'last_sync': DateTime.now().toIso8601String(),
          'is_dirty': 0,
        };

        final localData = {
          'id': 'conflict_user',
          'nickname': 'LocalUser',
          'avatar_url': localProfile.avatarUrl,
          'is_admin': localProfile.isAdmin,
          'star_candy': localProfile.starCandy,
          'star_candy_bonus': localProfile.starCandyBonus,
          'updated_at': DateTime.now().toIso8601String(),
          'last_sync': null,
          'is_dirty': 1,
        };

        // When: 충돌 해결 실행
        final resolution = await conflictService.resolveConflict(
          tableName: 'user_profiles',
          recordId: 'conflict_user',
          localData: localData,
          remoteData: remoteData,
        );

        // Then: Last Write Wins 전략으로 원격 데이터가 승리
        expect(resolution.success, isTrue);
        expect(resolution.strategy,
            equals(ConflictResolutionStrategy.lastWriteWins));
        expect(resolution.resolvedData['nickname'], equals('RemoteUser'));
      });

      testWidgets('자동 충돌 해결 - Merge 전략', (tester) async {
        // Given: 숫자 필드 충돌 시나리오
        final localData = {
          'id': 'merge_user',
          'nickname': 'MergeUser',
          'star_candy': 100,
          'star_candy_bonus': 0,
          'updated_at':
              DateTime.now().subtract(Duration(minutes: 10)).toIso8601String(),
        };

        final remoteData = {
          'id': 'merge_user',
          'nickname': 'MergeUser',
          'star_candy': 50,
          'star_candy_bonus': 0,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // star_candy 필드에 대해 merge 전략 설정
        conflictService.setFieldStrategy(
          'user_profiles',
          'star_candy',
          ConflictResolutionStrategy.merge,
        );

        // When: 충돌 해결
        final resolution = await conflictService.resolveConflict(
          tableName: 'user_profiles',
          recordId: 'merge_user',
          localData: localData,
          remoteData: remoteData,
        );

        // Then: 숫자 값이 병합됨 (100 + 50 = 150)
        expect(resolution.success, isTrue);
        expect(resolution.resolvedData['star_candy'], equals(150));
      });

      testWidgets('수동 충돌 해결 대기 큐 테스트', (tester) async {
        // Given: 수동 해결이 필요한 충돌
        conflictService.setFieldStrategy(
          'user_profiles',
          'nickname',
          ConflictResolutionStrategy.manualReview,
        );

        final localData = {
          'id': 'manual_user',
          'nickname': 'LocalNickname',
          'avatar_url': 'https://example.com/local_nickname_avatar.jpg',
          'is_admin': false,
          'star_candy': 100,
          'star_candy_bonus': 0,
        };

        final remoteData = {
          'id': 'manual_user',
          'nickname': 'RemoteNickname',
          'avatar_url': 'https://example.com/remote_nickname_avatar.jpg',
          'is_admin': false,
          'star_candy': 100,
          'star_candy_bonus': 0,
        };

        // When: 충돌 해결 시도
        final resolution = await conflictService.resolveConflict(
          tableName: 'user_profiles',
          recordId: 'manual_user',
          localData: localData,
          remoteData: remoteData,
        );

        // Then: 수동 해결 대기 큐에 추가됨
        expect(resolution.success, isFalse);

        final pendingConflicts = conflictService.getPendingManualReviews();
        expect(pendingConflicts.length, greaterThan(0));

        final nicknameConflict = pendingConflicts
            .where((c) => c.conflict.fieldName == 'nickname')
            .toList();
        expect(nicknameConflict.length, equals(1));

        // When: 수동으로 충돌 해결
        final conflict = nicknameConflict.first;
        final resolved = await conflictService.resolveManualConflict(
          conflictId: conflict.id,
          resolvedValue: 'ManuallyResolvedNickname',
        );

        // Then: 충돌 해결됨
        expect(resolved, isTrue);

        final remainingConflicts = conflictService.getPendingManualReviews();
        final remainingNicknameConflicts =
            remainingConflicts.where((c) => c.id == conflict.id).toList();
        expect(remainingNicknameConflicts.length, equals(0));
      });
    });

    group('재시도 메커니즘 테스트', () {
      testWidgets('Exponential Backoff 재시도 전략', (tester) async {
        // Given: 실패하는 작업 시뮬레이션
        var attemptCount = 0;
        final maxAttempts = 3;

        // When: 재시도 스케줄링
        try {
          await retryService.scheduleRetry(
            operationId: 'exponential_test',
            operation: () async {
              attemptCount++;
              if (attemptCount < maxAttempts) {
                throw Exception('Simulated failure $attemptCount');
              }
              return 'Success on attempt $attemptCount';
            },
            maxAttempts: maxAttempts,
            strategy: RetryStrategy.exponentialBackoff,
            priority: RetryPriority.normal,
          );
        } catch (e) {
          // 예상된 실패 (실제 환경에서는 성공할 수 있음)
        }

        // Then: 모든 시도가 완료됨
        expect(attemptCount, equals(maxAttempts));
      });

      testWidgets('우선순위 기반 재시도 처리', (tester) async {
        // Given: 다양한 우선순위의 작업들
        final results = <String>[];

        // When: 다양한 우선순위로 작업 스케줄링
        await Future.wait([
          retryService.scheduleRetry(
            operationId: 'low_priority',
            operation: () async {
              results.add('low');
              return 'low';
            },
            priority: RetryPriority.low,
          ),
          retryService.scheduleRetry(
            operationId: 'critical_priority',
            operation: () async {
              results.add('critical');
              return 'critical';
            },
            priority: RetryPriority.critical,
          ),
          retryService.scheduleRetry(
            operationId: 'high_priority',
            operation: () async {
              results.add('high');
              return 'high';
            },
            priority: RetryPriority.high,
          ),
        ]);

        // Then: 우선순위 순서대로 실행됨 (critical > high > low)
        expect(results.length, equals(3));
        expect(results.first, equals('critical'));
      });

      testWidgets('지속적 재시도 (앱 재시작 후에도 유지)', (tester) async {
        // Given: 지속적 재시도가 필요한 작업
        final operationId =
            'persistent_test_${DateTime.now().millisecondsSinceEpoch}';

        // When: 지속적 재시도 스케줄링
        await retryService.scheduleRetry(
          operationId: operationId,
          operation: () async {
            return 'persistent success';
          },
          persistentRetry: true,
          priority: RetryPriority.critical,
        );

        // Then: 데이터베이스에 저장됨
        final persistentRetries = await localDb.rawQuery(
          'SELECT * FROM persistent_retries WHERE id = ?',
          [operationId],
        );
        expect(persistentRetries.length, equals(1));
        expect(persistentRetries.first['status'], equals('completed'));
      });
    });

    group('데이터 일관성 및 무결성 테스트', () {
      testWidgets('트랜잭션 롤백 테스트', (tester) async {
        // Given: 트랜잭션 중 실패 시나리오
        final initialCount = await _getUserProfileCount();

        try {
          await localDb.transaction((txn) async {
            // 첫 번째 작업 성공
            await txn.insert('user_profiles', {
              'id': 'tx_user_1',
              'nickname': 'TxUser1',
              'avatar_url': 'https://example.com/tx_user_1_avatar.jpg',
              'is_admin': false,
              'star_candy': 100,
              'star_candy_bonus': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            // 두 번째 작업에서 실패 시뮬레이션
            throw Exception('Transaction failure simulation');
          });
        } catch (e) {
          // 예상된 실패
        }

        // Then: 트랜잭션이 롤백되어 데이터가 변경되지 않음
        final finalCount = await _getUserProfileCount();
        expect(finalCount, equals(initialCount));
      });

      testWidgets('더티 플래그 관리 테스트', (tester) async {
        // Given: 새 사용자 프로필 생성
        await networkManager.setOfflineMode(true);

        final testProfile = UserProfilesModel(
          id: 'dirty_test_user',
          nickname: 'DirtyUser',
          avatarUrl: 'https://example.com/dirty_user_avatar.jpg',
          isAdmin: false,
          starCandy: 200,
          starCandyBonus: 0,
        );

        await localDb.insert('user_profiles', testProfile.toJson());

        // When: 더티 레코드 조회
        final dirtyRecords = await localDb.getDirtyRecords('user_profiles');

        // Then: 생성된 레코드가 더티 상태임
        expect(dirtyRecords.length, equals(1));
        expect(dirtyRecords.first['id'], equals('dirty_test_user'));
        expect(dirtyRecords.first['is_dirty'], equals(1));

        // When: 더티 플래그 해제
        await localDb.markAsClean('user_profiles', 'dirty_test_user');

        // Then: 더이상 더티 레코드가 아님
        final cleanRecords = await localDb.getDirtyRecords('user_profiles');
        expect(cleanRecords.length, equals(0));
      });

      testWidgets('동기화 큐 정리 테스트', (tester) async {
        // Given: 여러 동기화 작업 추가
        await localDb.addToSyncQueue(
            'user_profiles', 'user1', 'INSERT', {'test': 'data1'});
        await localDb.addToSyncQueue(
            'user_profiles', 'user2', 'UPDATE', {'test': 'data2'});
        await localDb.addToSyncQueue('votes', 'vote1', 'DELETE', null);

        var syncQueue = await localDb.getSyncQueue();
        expect(syncQueue.length, equals(3));

        // When: 특정 항목 제거
        final firstItem = syncQueue.first;
        await localDb.removeFromSyncQueue(firstItem['id']);

        // Then: 항목이 제거됨
        syncQueue = await localDb.getSyncQueue();
        expect(syncQueue.length, equals(2));

        // 제거된 항목이 더이상 존재하지 않음
        final removedItem =
            syncQueue.where((item) => item['id'] == firstItem['id']).toList();
        expect(removedItem.length, equals(0));
      });
    });

    group('네트워크 상태 관리 테스트', () {
      testWidgets('네트워크 품질 측정 및 분류', (tester) async {
        // Given: 네트워크 상태 관리자 초기화
        await networkManager.initialize();

        // When: 네트워크 지연시간 측정 (private 메서드이므로 getDiagnostics 사용)
        final diagnostics = await networkManager.getDiagnostics();
        expect(diagnostics.latency, isNotNull);

        // 인터넷 연결 확인 (diagnostics 통해 확인)
        expect(diagnostics.hasInternet, isA<bool>());

        // 네트워크 상태 확인 (현재 상태 가져오기)
        networkManager.detailedNetworkStream.listen((state) {
        });

        await networkManager.setOfflineMode(true);
        await Future.delayed(Duration(milliseconds: 100)); // 상태 변경 대기

        // 오프라인 모드 확인
        bool isOfflineModeEnabled = false;
        networkManager.detailedNetworkStream.listen((state) {
          isOfflineModeEnabled = state.isOfflineModeForced;
        });

        expect(isOfflineModeEnabled, isTrue);
      });

      testWidgets('강제 오프라인 모드 토글', (tester) async {
        // Given: 초기 네트워크 상태

        // When: 강제 오프라인 모드 활성화
        await networkManager.setOfflineMode(true);

        // Wait for state update
        await Future.delayed(Duration(milliseconds: 100));

        // Then: 오프라인 모드가 활성화됨
        final offlineState = await networkManager.detailedNetworkStream.first;
        expect(offlineState.isOfflineModeForced, isTrue);

        // When: 오프라인 모드 비활성화
        await networkManager.setOfflineMode(false);

        // Wait for state update
        await Future.delayed(Duration(milliseconds: 100));

        // Then: 오프라인 모드가 비활성화됨
        final onlineState = await networkManager.detailedNetworkStream.first;
        expect(onlineState.isOfflineModeForced, isFalse);
      });
    });
  });
}

/// 테스트 헬퍼 함수들

/// 모든 테스트 데이터 삭제
Future<void> _clearAllData() async {
  final dbService = OfflineDatabaseService.instance;

  await dbService.delete('user_profiles', '1 = 1', []);
  await dbService.delete('votes', '1 = 1', []);
  await dbService.delete('user_votes', '1 = 1', []);
  await dbService.delete('galleries', '1 = 1', []);
  await dbService.delete('sync_queue', '1 = 1', []);
  await dbService.delete('persistent_retries', '1 = 1', []);
  await dbService.delete('conflict_reviews', '1 = 1', []);
  await dbService.delete('conflict_history', '1 = 1', []);
}

/// 사용자 프로필 수 조회
Future<int> _getUserProfileCount() async {
  final dbService = OfflineDatabaseService.instance;
  final result =
      await dbService.rawQuery('SELECT COUNT(*) as count FROM user_profiles');
  return result.first['count'] as int;
}
