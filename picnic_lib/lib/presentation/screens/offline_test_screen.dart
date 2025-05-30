import 'package:flutter/material.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/enhanced_retry_service.dart';
import 'package:picnic_lib/core/services/network_state_manager.dart';
import 'package:picnic_lib/core/services/offline_sync_service.dart';
import 'package:picnic_lib/core/services/conflict_resolution_service.dart';
import 'package:picnic_lib/presentation/widgets/offline_mode_indicator.dart';
import 'package:picnic_lib/presentation/widgets/conflict_resolution_dialog.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 오프라인 모드 기능 테스트 화면
/// 개발 및 테스트 목적으로 오프라인 모드의 다양한 기능들을 테스트할 수 있습니다.
class OfflineTestScreen extends StatefulWidget {
  const OfflineTestScreen({super.key});

  @override
  State<OfflineTestScreen> createState() => _OfflineTestScreenState();
}

class _OfflineTestScreenState extends State<OfflineTestScreen> {
  final OfflineDatabaseService _localDb = OfflineDatabaseService.instance;
  final EnhancedRetryService _retryService = EnhancedRetryService.instance;
  final NetworkStateManager _networkManager = NetworkStateManager.instance;
  final OfflineSyncService _syncService = OfflineSyncService.instance;
  final ConflictResolutionService _conflictResolutionService = ConflictResolutionService.instance;

  Map<String, dynamic>? _queueStatus;
  Map<String, dynamic>? _dbStats;
  String _testResults = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _localDb.init();
      await _networkManager.initialize();
      await _syncService.initialize();
      await _conflictResolutionService.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
      _updateStats();
      logger.i('Offline test services initialized');
    } catch (e, s) {
      logger.e('Failed to initialize offline test services', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _updateStats() async {
    if (!_isInitialized) return;

    try {
      final queueStatus = _retryService.getQueueStatus();
      final syncQueueCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
      final persistentRetryCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM persistent_retries');
      final userProfilesCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM user_profiles');
      final votesCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM votes');
      final conflictReviewsCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM conflict_reviews WHERE status = "pending"');
      final conflictHistoryCount = await _localDb.rawQuery('SELECT COUNT(*) as count FROM conflict_history');

      setState(() {
        _queueStatus = queueStatus;
        _dbStats = {
          'sync_queue': syncQueueCount.first['count'],
          'persistent_retries': persistentRetryCount.first['count'],
          'user_profiles': userProfilesCount.first['count'],
          'votes': votesCount.first['count'],
          'pending_conflicts': conflictReviewsCount.first['count'],
          'resolved_conflicts': conflictHistoryCount.first['count'],
        };
      });
    } catch (e) {
      logger.e('Error updating stats', error: e);
    }
  }

  Future<void> _testDatabaseOperations() async {
    setState(() {
      _testResults = 'Running database tests...';
    });

    try {
      // 테스트 사용자 프로필 삽입
      await _localDb.insert('user_profiles', {
        'id': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        'nickname': 'Test User',
        'avatar_url': 'https://example.com/avatar.jpg',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': 1,
      });

      // 테스트 투표 데이터 삽입
      await _localDb.insert('votes', {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': 'Test Vote',
        'description': 'This is a test vote',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'status': 'active',
        'category': 'test',
        'vote_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': 1,
      });

      // 동기화 큐에 테스트 항목 추가
      await _localDb.addToSyncQueue('test_table', 'test_record', 'INSERT', {
        'test_field': 'test_value',
      });

      await _updateStats();
      setState(() {
        _testResults = 'Database operations completed successfully!';
      });
    } catch (e, s) {
      logger.e('Database test failed', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Database test failed: $e';
      });
    }
  }

  Future<void> _testRetryMechanism() async {
    setState(() {
      _testResults = 'Testing retry mechanism...';
    });

    try {
      int attemptCount = 0;
      
      // 실패하는 작업을 재시도 큐에 추가
      await _retryService.scheduleRetry(
        operationId: 'test_operation_${DateTime.now().millisecondsSinceEpoch}',
        operation: () async {
          attemptCount++;
          logger.d('Test retry attempt: $attemptCount');
          
          if (attemptCount < 3) {
            throw Exception('Simulated failure attempt $attemptCount');
          }
          
          return 'Success after $attemptCount attempts';
        },
        priority: RetryPriority.high,
        maxAttempts: 5,
        strategy: RetryStrategy.exponentialBackoff,
        persistentRetry: false,
      );

      await _updateStats();
      setState(() {
        _testResults = 'Retry operation scheduled. Check logs for progress.';
      });
    } catch (e, s) {
      logger.e('Retry test failed', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Retry test failed: $e';
      });
    }
  }

  Future<void> _testConflictResolution() async {
    setState(() {
      _testResults = 'Testing conflict resolution...';
    });

    try {
      // 테스트용 로컬/원격 데이터 생성
      final localData = {
        'id': 'test_user_conflict',
        'nickname': 'Local User',
        'star_candy': 100,
        'bio': 'Local bio',
        'updated_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'is_dirty': 1,
      };

      final remoteData = {
        'id': 'test_user_conflict',
        'nickname': 'Remote User',
        'star_candy': 150,
        'bio': 'Remote bio',
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': 0,
      };

      // 충돌 해결 테스트
      final resolution = await _conflictResolutionService.resolveConflict(
        tableName: 'user_profiles',
        recordId: 'test_user_conflict',
        localData: localData,
        remoteData: remoteData,
      );

      await _updateStats();
      setState(() {
        _testResults = 'Conflict resolution completed!\n'
                     'Strategy: ${resolution.strategy.name}\n'
                     'Success: ${resolution.success}\n'
                     'Conflicts: ${resolution.conflictDetails.length}';
      });
    } catch (e, s) {
      logger.e('Conflict resolution test failed', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Conflict resolution test failed: $e';
      });
    }
  }

  Future<void> _testManualConflictResolution() async {
    setState(() {
      _testResults = 'Creating manual conflict for testing...';
    });

    try {
      // 수동 해결이 필요한 충돌 생성
      final localData = {
        'id': 'test_manual_conflict',
        'nickname': 'Important Local Name',
        'bio': 'Local description',
        'updated_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        'is_dirty': 1,
      };

      final remoteData = {
        'id': 'test_manual_conflict',
        'nickname': 'Important Remote Name',
        'bio': 'Remote description',
        'updated_at': DateTime.now().toIso8601String(),
        'is_dirty': 0,
      };

      // nickname 필드를 수동 리뷰로 설정
      _conflictResolutionService.setFieldStrategy(
        'user_profiles',
        'nickname',
        ConflictResolutionStrategy.manualReview,
      );

      // 충돌 해결 시도 (수동 리뷰 대기 상태가 됨)
      await _conflictResolutionService.resolveConflict(
        tableName: 'user_profiles',
        recordId: 'test_manual_conflict',
        localData: localData,
        remoteData: remoteData,
      );

      // 대기 중인 충돌 확인
      final pendingConflicts = _conflictResolutionService.getPendingManualReviews();
      
      if (pendingConflicts.isNotEmpty && mounted) {
        // 첫 번째 충돌에 대한 수동 해결 대화상자 표시
        await ConflictResolutionDialog.show(
          context,
          pendingConflicts.first,
          onResolved: () {
            _updateStats();
            setState(() {
              _testResults = 'Manual conflict resolved successfully!';
            });
          },
        );
      }

      await _updateStats();
      setState(() {
        _testResults = 'Manual conflict resolution dialog shown. '
                     'Pending conflicts: ${pendingConflicts.length}';
      });
    } catch (e, s) {
      logger.e('Manual conflict test failed', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Manual conflict test failed: $e';
      });
    }
  }

  Future<void> _showPendingConflicts() async {
    final pendingConflicts = _conflictResolutionService.getPendingManualReviews();
    
    if (pendingConflicts.isEmpty) {
      setState(() {
        _testResults = 'No pending conflicts to resolve.';
      });
      return;
    }

    if (mounted) {
      await ConflictResolutionDialog.show(
        context,
        pendingConflicts.first,
        onResolved: () {
          _updateStats();
          setState(() {
            _testResults = 'Conflict resolved! Check for more pending conflicts.';
          });
        },
      );
    }
  }

  Future<void> _clearDatabase() async {
    setState(() {
      _testResults = 'Clearing database...';
    });

    try {
      await _localDb.delete('user_profiles', '1 = 1', []);
      await _localDb.delete('votes', '1 = 1', []);
      await _localDb.delete('sync_queue', '1 = 1', []);
      await _localDb.delete('persistent_retries', '1 = 1', []);

      await _updateStats();
      setState(() {
        _testResults = 'Database cleared successfully!';
      });
    } catch (e, s) {
      logger.e('Database clear failed', error: e, stackTrace: s);
      setState(() {
        _testResults = 'Database clear failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오프라인 모드 테스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // 네트워크 상태 표시
          const OfflineModeIndicator(showWhenOnline: true),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildTestButtonsSection(),
                  const SizedBox(height: 24),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시스템 상태',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!_isInitialized)
              const CircularProgressIndicator()
            else ...[
              _buildStatRow('초기화 상태', _isInitialized ? '완료' : '진행중'),
              if (_queueStatus != null) ...[
                _buildStatRow('대기 중인 작업', '${_queueStatus!['pending_operations']}개'),
                _buildStatRow('활성 재시도', '${_queueStatus!['active_retries']}개'),
                _buildStatRow('서킷 브레이커', '${_queueStatus!['circuit_breakers']}개'),
              ],
              if (_dbStats != null) ...[
                const Divider(),
                Text(
                  '데이터베이스 통계',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildStatRow('동기화 큐', '${_dbStats!['sync_queue']}개'),
                _buildStatRow('지속적 재시도', '${_dbStats!['persistent_retries']}개'),
                _buildStatRow('사용자 프로필', '${_dbStats!['user_profiles']}개'),
                _buildStatRow('투표 데이터', '${_dbStats!['votes']}개'),
                _buildStatRow('대기 중인 충돌', '${_dbStats!['pending_conflicts']}개'),
                _buildStatRow('해결된 충돌', '${_dbStats!['resolved_conflicts']}개'),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtonsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '테스트 기능',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _testDatabaseOperations : null,
                icon: const Icon(Icons.storage),
                label: const Text('데이터베이스 작업 테스트'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _testRetryMechanism : null,
                icon: const Icon(Icons.replay),
                label: const Text('재시도 메커니즘 테스트'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _testConflictResolution : null,
                icon: const Icon(Icons.merge),
                label: const Text('충돌 해결 테스트'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _testManualConflictResolution : null,
                icon: const Icon(Icons.build),
                label: const Text('수동 충돌 해결 테스트'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitialized ? _showPendingConflicts : null,
                icon: const Icon(Icons.list_alt),
                label: const Text('대기 중인 충돌 보기'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isInitialized ? () async {
                  await _networkManager.setOfflineMode(
                    !_networkManager.isOfflineModeEnabled
                  );
                } : null,
                icon: const Icon(Icons.cloud_off),
                label: const Text('오프라인 모드 토글'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isInitialized ? _clearDatabase : null,
                icon: const Icon(Icons.clear_all),
                label: const Text('데이터베이스 초기화'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '테스트 결과',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResults.isEmpty ? '테스트를 실행하려면 위의 버튼을 눌러주세요.' : _testResults,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 