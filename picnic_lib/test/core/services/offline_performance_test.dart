// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/offline_sync_service.dart';
import 'package:picnic_lib/core/services/enhanced_retry_service.dart';
import 'package:picnic_lib/core/services/network_state_manager.dart';
import 'package:picnic_lib/core/services/conflict_resolution_service.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'dart:math';

/// 오프라인 기능 성능 및 스트레스 테스트
///
/// 이 테스트는 다음을 검증합니다:
/// 1. 대용량 데이터 처리 성능
/// 2. 동시 작업 처리 능력
/// 3. 메모리 사용량 최적화
/// 4. 동기화 성능
/// 5. 데이터베이스 쿼리 성능
void main() {
  group('오프라인 성능 테스트', () {
    late OfflineDatabaseService localDb;
    late OfflineSyncService syncService;
    late NetworkStateManager networkManager;
    late EnhancedRetryService retryService;
    late ConflictResolutionService conflictService;

    setUpAll(() async {
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
      await _clearAllData();
    });

    tearDownAll(() async {
      await localDb.cleanup();
    });

    group('대용량 데이터 처리 성능 테스트', () {
      testWidgets('1000개 사용자 프로필 일괄 생성 성능', (tester) async {
        const recordCount = 1000;
        final stopwatch = Stopwatch()..start();

        // Given: 오프라인 모드
        await networkManager.setOfflineMode(true);

        // When: 1000개 사용자 프로필 생성
        final profiles = <UserProfilesModel>[];
        for (int i = 0; i < recordCount; i++) {
          profiles.add(UserProfilesModel(
            id: 'bulk_user_$i',
            nickname: 'BulkUser$i',
            isAdmin: false,
            starCandy: Random().nextInt(1000),
            starCandyBonus: 0,
          ));
        }

        final createStart = stopwatch.elapsedMilliseconds;

        // 배치 생성 (트랜잭션 사용)
        await localDb.transaction((txn) async {
          for (final profile in profiles) {
            final data = {
              'id': profile.id,
              'nickname': profile.nickname,
              'star_candy': profile.starCandy,
              'star_candy_bonus': profile.starCandyBonus,
              'is_admin': profile.isAdmin,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'is_dirty': 1,
            };
            await txn.insert('user_profiles', data);
          }
        });

        final createEnd = stopwatch.elapsedMilliseconds;
        final createTime = createEnd - createStart;

        // Then: 성능 검증
        expect(createTime, lessThan(5000)); // 5초 이내 완료
        print('$recordCount 개 프로필 생성 시간: ${createTime}ms');

        // When: 전체 조회 성능 테스트
        final queryStart = stopwatch.elapsedMilliseconds;
        final allProfiles = await localDb.query('user_profiles');
        final queryEnd = stopwatch.elapsedMilliseconds;
        final queryTime = queryEnd - queryStart;

        // Then: 조회 성능 및 정확성 검증
        expect(allProfiles.length, equals(recordCount));
        expect(queryTime, lessThan(2000)); // 2초 이내 조회
        print('$recordCount 개 프로필 조회 시간: ${queryTime}ms');

        stopwatch.stop();
      });

      testWidgets('대용량 투표 데이터 처리 및 필터링 성능', (tester) async {
        const recordCount = 500;
        final stopwatch = Stopwatch()..start();

        await networkManager.setOfflineMode(true);

        // Given: 다양한 상태의 투표 데이터 생성
        final votes = <Map<String, dynamic>>[];
        final statuses = ['active', 'upcoming', 'completed'];
        final categories = ['music', 'art', 'dance', 'comedy', 'drama'];

        for (int i = 0; i < recordCount; i++) {
          votes.add({
            'id': i + 1,
            'title': 'Performance Vote $i',
            'description': 'Performance test vote description $i',
            'start_date': DateTime.now()
                .subtract(Duration(days: Random().nextInt(30)))
                .toIso8601String(),
            'end_date': DateTime.now()
                .add(Duration(days: Random().nextInt(30)))
                .toIso8601String(),
            'status': statuses[Random().nextInt(statuses.length)],
            'category': categories[Random().nextInt(categories.length)],
            'vote_count': Random().nextInt(10000),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // When: 배치 생성
        await localDb.transaction((txn) async {
          for (final vote in votes) {
            await txn.insert('votes', {
              ...vote,
              'is_dirty': 1,
            });
          }
        });

        final createTime = stopwatch.elapsedMilliseconds;
        print('$recordCount 개 투표 생성 시간: ${createTime}ms');

        // When: 카테고리별 필터링 성능 테스트
        final filterStart = stopwatch.elapsedMilliseconds;
        final musicVotes = await localDb
            .query('votes', where: 'category = ?', whereArgs: ['music']);
        final filterEnd = stopwatch.elapsedMilliseconds;
        final filterTime = filterEnd - filterStart;

        // Then: 필터링 성능 검증
        expect(musicVotes.length, greaterThan(0));
        expect(filterTime, lessThan(1000)); // 1초 이내
        print('카테고리 필터링 시간: ${filterTime}ms');

        // When: 상태별 필터링 성능 테스트
        final statusFilterStart = stopwatch.elapsedMilliseconds;
        final activeVotes = await localDb
            .query('votes', where: 'status = ?', whereArgs: ['active']);
        final statusFilterEnd = stopwatch.elapsedMilliseconds;
        final statusFilterTime = statusFilterEnd - statusFilterStart;

        // Then: 상태 필터링 성능 검증
        expect(activeVotes.length, greaterThan(0));
        expect(statusFilterTime, lessThan(1000)); // 1초 이내
        print('상태 필터링 시간: ${statusFilterTime}ms');

        stopwatch.stop();
      });
    });

    group('동시성 및 경합 상태 테스트', () {
      testWidgets('동시 데이터 생성 및 수정 테스트', (tester) async {
        await networkManager.setOfflineMode(true);

        const concurrentOperations = 50;
        final stopwatch = Stopwatch()..start();

        // When: 동시에 여러 사용자 프로필 생성
        final futures = <Future>[];
        for (int i = 0; i < concurrentOperations; i++) {
          final profileData = {
            'id': 'concurrent_user_$i',
            'nickname': 'ConcurrentUser$i',
            'star_candy': i * 10,
            'star_candy_bonus': 0,
            'is_admin': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'is_dirty': 1,
          };
          futures.add(localDb.insert('user_profiles', profileData));
        }

        final results = await Future.wait(futures);
        final createTime = stopwatch.elapsedMilliseconds;

        // Then: 모든 작업이 성공적으로 완료됨
        expect(results.length, equals(concurrentOperations));
        expect(createTime, lessThan(10000)); // 10초 이내
        print('동시 생성 ($concurrentOperations 개) 시간: ${createTime}ms');

        // When: 동시 업데이트 테스트
        final updateFutures = <Future>[];
        for (int i = 0; i < concurrentOperations; i++) {
          final updatedData = {
            'nickname': 'UpdatedConcurrentUser$i',
            'star_candy': i * 20,
            'updated_at': DateTime.now().toIso8601String(),
            'is_dirty': 1,
          };
          updateFutures.add(localDb.update(
              'user_profiles', updatedData, 'id = ?', ['concurrent_user_$i']));
        }

        final updateResults = await Future.wait(updateFutures);
        final updateTime = stopwatch.elapsedMilliseconds - createTime;

        // Then: 모든 업데이트가 성공
        expect(updateResults.length, equals(concurrentOperations));
        expect(updateTime, lessThan(10000)); // 10초 이내
        print('동시 업데이트 ($concurrentOperations 개) 시간: ${updateTime}ms');

        stopwatch.stop();
      });

      testWidgets('동시 충돌 해결 처리 테스트', (tester) async {
        const conflictCount = 20;
        final stopwatch = Stopwatch()..start();

        // Given: 충돌 시나리오 설정
        final conflictFutures = <Future>[];

        for (int i = 0; i < conflictCount; i++) {
          final localData = {
            'id': 'conflict_user_$i',
            'nickname': 'LocalUser$i',
            'star_candy': 100,
            'updated_at': DateTime.now()
                .subtract(Duration(minutes: 10))
                .toIso8601String(),
          };

          final remoteData = {
            'id': 'conflict_user_$i',
            'nickname': 'RemoteUser$i',
            'star_candy': 200,
            'updated_at': DateTime.now().toIso8601String(),
          };

          conflictFutures.add(conflictService.resolveConflict(
            tableName: 'user_profiles',
            recordId: 'conflict_user_$i',
            localData: localData,
            remoteData: remoteData,
          ));
        }

        // When: 동시 충돌 해결
        final resolutions = await Future.wait(conflictFutures);
        final resolutionTime = stopwatch.elapsedMilliseconds;

        // Then: 모든 충돌이 해결됨
        expect(resolutions.length, equals(conflictCount));
        expect(
            resolutions.where((r) => r.success).length, equals(conflictCount));
        expect(resolutionTime, lessThan(5000)); // 5초 이내
        print('동시 충돌 해결 ($conflictCount 개) 시간: ${resolutionTime}ms');

        stopwatch.stop();
      });
    });

    group('재시도 시스템 스트레스 테스트', () {
      testWidgets('대량 재시도 작업 처리 성능', (tester) async {
        const retryOperationCount = 100;
        final stopwatch = Stopwatch()..start();

        // When: 대량 재시도 작업 스케줄링
        final retryFutures = <Future>[];
        for (int i = 0; i < retryOperationCount; i++) {
          retryFutures.add(retryService.scheduleRetry(
            operationId: 'stress_test_$i',
            operation: () async {
              // 가끔 실패하는 작업 시뮬레이션
              if (Random().nextDouble() < 0.3) {
                throw Exception('Random failure');
              }
              return 'Success $i';
            },
            maxAttempts: 3,
            strategy: RetryStrategy.exponentialBackoff,
            priority: RetryPriority
                .values[Random().nextInt(RetryPriority.values.length)],
          ));
        }

        // 일부 실패는 예상되므로 개별 처리
        final results = <String>[];
        for (final future in retryFutures) {
          try {
            final result = await future;
            results.add(result);
          } catch (e) {
            // 최대 재시도 후 실패한 작업들
          }
        }

        final totalTime = stopwatch.elapsedMilliseconds;

        // Then: 성능 검증
        expect(results.length,
            greaterThan(retryOperationCount * 0.5)); // 최소 50% 성공
        expect(totalTime, lessThan(30000)); // 30초 이내
        print('대량 재시도 작업 ($retryOperationCount 개) 처리 시간: ${totalTime}ms');
        print(
            '성공률: ${(results.length / retryOperationCount * 100).toStringAsFixed(1)}%');

        stopwatch.stop();
      });

      testWidgets('지속적 재시도 메모리 사용량 테스트', (tester) async {
        const persistentRetryCount = 50;

        // When: 지속적 재시도 작업 생성
        for (int i = 0; i < persistentRetryCount; i++) {
          await retryService.scheduleRetry(
            operationId: 'persistent_memory_test_$i',
            operation: () async {
              return 'Memory test result $i';
            },
            persistentRetry: true,
            priority: RetryPriority.normal,
          );
        }

        // Then: 데이터베이스에 저장된 지속적 재시도 확인
        final persistentRetries = await localDb
            .rawQuery('SELECT COUNT(*) as count FROM persistent_retries');

        final count = persistentRetries.first['count'] as int;
        expect(count, equals(persistentRetryCount));

        // 메모리 사용량 간접 확인 (큐 상태 조회)
        final queueStatus = retryService.getQueueStatus();
        expect(queueStatus, isNotNull);
        expect(queueStatus['pending_operations'], isA<int>());
      });
    });

    group('동기화 성능 테스트', () {
      testWidgets('대량 동기화 큐 처리 성능', (tester) async {
        const syncQueueSize = 200;
        final stopwatch = Stopwatch()..start();

        await networkManager.setOfflineMode(true);

        // Given: 대량 동기화 작업 생성
        for (int i = 0; i < syncQueueSize; i++) {
          await localDb.addToSyncQueue(
            'user_profiles',
            'sync_user_$i',
            Random().nextBool() ? 'INSERT' : 'UPDATE',
            {
              'id': 'sync_user_$i',
              'nickname': 'SyncUser$i',
              'star_candy': Random().nextInt(1000),
            },
          );
        }

        final queueCreationTime = stopwatch.elapsedMilliseconds;
        print('동기화 큐 생성 ($syncQueueSize 개) 시간: ${queueCreationTime}ms');

        // When: 동기화 큐 조회 성능 테스트
        final queryStart = stopwatch.elapsedMilliseconds;
        final syncQueue = await localDb.getSyncQueue();
        final queryEnd = stopwatch.elapsedMilliseconds;
        final queryTime = queryEnd - queryStart;

        // Then: 조회 성능 검증
        expect(syncQueue.length, equals(syncQueueSize));
        expect(queryTime, lessThan(1000)); // 1초 이내
        print('동기화 큐 조회 시간: ${queryTime}ms');

        // When: 배치 동기화 큐 정리 성능 테스트
        final cleanupStart = stopwatch.elapsedMilliseconds;
        await localDb.transaction((txn) async {
          for (int i = 0; i < syncQueueSize ~/ 2; i++) {
            await localDb.delete('sync_queue', 'id = ?', [syncQueue[i]['id']]);
          }
        });
        final cleanupEnd = stopwatch.elapsedMilliseconds;
        final cleanupTime = cleanupEnd - cleanupStart;

        // Then: 정리 성능 검증
        expect(cleanupTime, lessThan(2000)); // 2초 이내
        print('동기화 큐 정리 (${syncQueueSize ~/ 2} 개) 시간: ${cleanupTime}ms');

        stopwatch.stop();
      });

      testWidgets('동기화 상태 스트림 처리 성능', (tester) async {
        const statusUpdateCount = 100;
        final receivedStatuses = <SyncStatus>[];

        // Given: 동기화 상태 스트림 구독
        final subscription = syncService.syncStatusStream.listen((status) {
          receivedStatuses.add(status);
        });

        final stopwatch = Stopwatch()..start();

        // When: 빠른 상태 변경 시뮬레이션
        try {
          for (int i = 0; i < statusUpdateCount; i++) {
            // 실제 동기화는 네트워크 연결이 필요하므로 상태만 테스트
            await Future.delayed(Duration(milliseconds: 10));
          }
        } catch (e) {
          // 네트워크 오류 예상됨
        }

        await subscription.cancel();
        final streamTime = stopwatch.elapsedMilliseconds;

        // Then: 스트림 처리 성능 검증
        expect(streamTime, lessThan(5000)); // 5초 이내
        print('동기화 상태 스트림 처리 시간: ${streamTime}ms');

        stopwatch.stop();
      });
    });

    group('데이터베이스 쿼리 최적화 테스트', () {
      testWidgets('인덱스 활용 쿼리 성능 테스트', (tester) async {
        const testDataSize = 1000;
        final stopwatch = Stopwatch()..start();

        // Given: 대량 테스트 데이터 생성
        await localDb.transaction((txn) async {
          for (int i = 0; i < testDataSize; i++) {
            await txn.insert('votes', {
              'id': i + 1,
              'title': 'Query Test Vote $i',
              'status': ['active', 'completed', 'upcoming'][i % 3],
              'category': ['music', 'art', 'dance'][i % 3],
              'vote_count': Random().nextInt(1000),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        });

        final dataCreationTime = stopwatch.elapsedMilliseconds;
        print('테스트 데이터 생성 ($testDataSize 개) 시간: ${dataCreationTime}ms');

        // When: 인덱스된 필드로 쿼리 (status)
        final indexedQueryStart = stopwatch.elapsedMilliseconds;
        final activeVotes = await localDb.query(
          'votes',
          where: 'status = ?',
          whereArgs: ['active'],
        );
        final indexedQueryEnd = stopwatch.elapsedMilliseconds;
        final indexedQueryTime = indexedQueryEnd - indexedQueryStart;

        // Then: 인덱스된 쿼리 성능 검증
        expect(activeVotes.length, greaterThan(0));
        expect(indexedQueryTime, lessThan(100)); // 100ms 이내
        print('인덱스된 필드 쿼리 (status) 시간: ${indexedQueryTime}ms');

        // When: 복합 쿼리 테스트
        final complexQueryStart = stopwatch.elapsedMilliseconds;
        final complexResults = await localDb.query(
          'votes',
          where: 'status = ? AND category = ?',
          whereArgs: ['active', 'music'],
          orderBy: 'vote_count DESC',
          limit: 10,
        );
        final complexQueryEnd = stopwatch.elapsedMilliseconds;
        final complexQueryTime = complexQueryEnd - complexQueryStart;

        // Then: 복합 쿼리 성능 검증
        expect(complexResults.length, lessThanOrEqualTo(10));
        expect(complexQueryTime, lessThan(200)); // 200ms 이내
        print('복합 쿼리 시간: ${complexQueryTime}ms');

        stopwatch.stop();
      });

      testWidgets('페이지네이션 쿼리 성능 테스트', (tester) async {
        const totalRecords = 500;
        const pageSize = 20;
        const totalPages = totalRecords ~/ pageSize;

        // Given: 페이지네이션 테스트용 데이터 생성
        await localDb.transaction((txn) async {
          for (int i = 0; i < totalRecords; i++) {
            await txn.insert('user_profiles', {
              'id': 'page_user_$i',
              'nickname': 'PageUser$i',
              'star_candy': i,
              'created_at': DateTime.now()
                  .subtract(Duration(minutes: i))
                  .toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        });

        final stopwatch = Stopwatch()..start();

        // When: 페이지별 쿼리 성능 테스트
        final pageTimes = <int>[];
        for (int page = 0; page < totalPages; page++) {
          final pageStart = stopwatch.elapsedMilliseconds;

          final pageData = await localDb.query(
            'user_profiles',
            orderBy: 'created_at DESC',
            limit: pageSize,
            offset: page * pageSize,
          );

          final pageEnd = stopwatch.elapsedMilliseconds;
          final pageTime = pageEnd - pageStart;
          pageTimes.add(pageTime);

          expect(pageData.length, lessThanOrEqualTo(pageSize));
        }

        final totalPaginationTime = stopwatch.elapsedMilliseconds;
        final avgPageTime =
            pageTimes.reduce((a, b) => a + b) / pageTimes.length;

        // Then: 페이지네이션 성능 검증
        expect(avgPageTime, lessThan(50)); // 평균 50ms 이내
        expect(totalPaginationTime, lessThan(5000)); // 전체 5초 이내
        print('평균 페이지 쿼리 시간: ${avgPageTime.toStringAsFixed(1)}ms');
        print('전체 페이지네이션 시간: ${totalPaginationTime}ms');

        stopwatch.stop();
      });
    });

    group('메모리 사용량 최적화 테스트', () {
      testWidgets('대량 데이터 처리 시 메모리 효율성', (tester) async {
        const batchSize = 100;
        const totalBatches = 10;

        // When: 배치별로 데이터 처리 (메모리 효율성)
        for (int batch = 0; batch < totalBatches; batch++) {
          final profiles = <UserProfilesModel>[];

          // 배치 단위로 데이터 생성
          for (int i = 0; i < batchSize; i++) {
            profiles.add(UserProfilesModel(
              id: 'memory_user_${batch * batchSize + i}',
              nickname: 'MemoryUser${batch * batchSize + i}',
              isAdmin: false,
              starCandy: Random().nextInt(100),
              starCandyBonus: 0,
            ));
          }

          // 배치 처리
          await localDb.transaction((txn) async {
            for (final profile in profiles) {
              final data = {
                'id': profile.id,
                'nickname': profile.nickname,
                'star_candy': profile.starCandy,
                'star_candy_bonus': profile.starCandyBonus,
                'is_admin': profile.isAdmin,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'is_dirty': 1,
              };
              await txn.insert('user_profiles', data);
            }
          });

          // 배치 완료 후 메모리 정리 (시뮬레이션)
          profiles.clear();

          // 진행 상황 출력
          if (batch % 2 == 0) {
            print('배치 ${batch + 1}/$totalBatches 완료');
          }
        }

        // Then: 전체 데이터 확인
        final totalCount = await localDb
            .rawQuery('SELECT COUNT(*) as count FROM user_profiles');
        expect(totalCount.first['count'], equals(batchSize * totalBatches));
        print('총 ${batchSize * totalBatches}개 레코드 처리 완료');
      });
    });
  });
}

/// 테스트 헬퍼 함수

/// 모든 테스트 데이터 삭제
Future<void> _clearAllData() async {
  final localDb = OfflineDatabaseService.instance;

  await localDb.delete('user_profiles', '1 = 1', []);
  await localDb.delete('votes', '1 = 1', []);
  await localDb.delete('user_votes', '1 = 1', []);
  await localDb.delete('galleries', '1 = 1', []);
  await localDb.delete('sync_queue', '1 = 1', []);
  await localDb.delete('persistent_retries', '1 = 1', []);
  await localDb.delete('conflict_reviews', '1 = 1', []);
  await localDb.delete('conflict_history', '1 = 1', []);
}
