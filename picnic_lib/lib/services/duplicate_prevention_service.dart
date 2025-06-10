import 'dart:async';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/repositories/vote_request_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 중복 방지 전담 서비스 컴포넌트
///
/// 투표 신청, 투표 참여 등에서 중복을 방지하는 로직을 제공합니다.
/// 메모리 캐싱을 통해 효율적인 중복 감지를 지원합니다.
class DuplicatePreventionService {
  final VoteRequestRepository _voteRequestRepository;

  // 메모리 캐시: userId_voteId -> hasRequested
  final Map<String, bool> _requestCache = {};

  // 캐시 만료 시간 (5분)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // 캐시 타임스탬프: userId_voteId -> timestamp
  final Map<String, DateTime> _cacheTimestamps = {};

  // 진행 중인 요청들을 추적하여 동시 요청 방지
  final Map<String, Completer<bool>> _pendingRequests = {};

  DuplicatePreventionService(this._voteRequestRepository);

  /// 사용자가 특정 투표에 이미 신청했는지 확인 (캐싱 지원)
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  /// [forceRefresh] 캐시를 무시하고 강제로 새로 조회할지 여부
  ///
  /// Returns: 이미 신청한 경우 true, 아닌 경우 false
  /// Throws: [VoteRequestException] 조회 중 오류 발생 시
  Future<bool> hasUserRequestedVote(
    String userId,
    String voteId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${userId}_$voteId';

    try {
      // 1. 진행 중인 동일한 요청이 있는지 확인
      if (_pendingRequests.containsKey(cacheKey)) {
        logger.d('동일한 요청이 진행 중 - 대기: $cacheKey');
        return await _pendingRequests[cacheKey]!.future;
      }

      // 2. 캐시 확인 (강제 새로고침이 아닌 경우)
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        final cachedResult = _requestCache[cacheKey]!;
        logger.d('캐시에서 중복 확인 결과 반환: $cacheKey -> $cachedResult');
        return cachedResult;
      }

      // 3. 새로운 요청 시작
      final completer = Completer<bool>();
      _pendingRequests[cacheKey] = completer;

      logger.d('데이터베이스에서 중복 확인 시작: $cacheKey');

      // 4. 데이터베이스 조회
      final hasRequested =
          await _voteRequestRepository.hasUserRequestedVote(voteId, userId);

      // 5. 캐시 업데이트
      _updateCache(cacheKey, hasRequested);

      // 6. 진행 중인 요청 완료 처리
      _pendingRequests.remove(cacheKey);
      completer.complete(hasRequested);

      logger.d('중복 확인 완료: $cacheKey -> $hasRequested');
      return hasRequested;
    } catch (e) {
      // 오류 발생 시 진행 중인 요청 정리
      final completer = _pendingRequests.remove(cacheKey);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(e);
      }

      logger.e('중복 확인 중 오류 발생: $cacheKey', error: e);
      throw VoteRequestException('중복 확인 중 오류가 발생했습니다: $e');
    }
  }

  /// 중복 신청 방지 검증
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  /// [forceRefresh] 캐시를 무시하고 강제로 새로 조회할지 여부
  ///
  /// Throws: [DuplicateVoteRequestException] 이미 신청한 경우
  /// Throws: [VoteRequestException] 조회 중 오류 발생 시
  Future<void> validateNoDuplicateRequest(
    String userId,
    String voteId, {
    bool forceRefresh = false,
  }) async {
    final hasRequested =
        await hasUserRequestedVote(userId, voteId, forceRefresh: forceRefresh);

    if (hasRequested) {
      throw const DuplicateVoteRequestException('이미 해당 투표에 신청하셨습니다.');
    }
  }

  /// 신청 완료 후 캐시 무효화
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  ///
  /// 신청이 성공적으로 완료된 후 호출하여 캐시를 업데이트합니다.
  void markUserAsRequested(String userId, String voteId) {
    final cacheKey = '${userId}_$voteId';
    _updateCache(cacheKey, true);
    logger.d('사용자 신청 완료로 캐시 업데이트: $cacheKey -> true');
  }

  /// 특정 사용자의 모든 캐시 무효화
  ///
  /// [userId] 사용자 ID
  ///
  /// 사용자 관련 모든 캐시를 제거합니다.
  void invalidateUserCache(String userId) {
    final keysToRemove = <String>[];

    for (final key in _requestCache.keys) {
      if (key.startsWith('${userId}_')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _requestCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    logger.d('사용자 캐시 무효화 완료: $userId (${keysToRemove.length}개 항목)');
  }

  /// 특정 투표의 모든 캐시 무효화
  ///
  /// [voteId] 투표 ID
  ///
  /// 투표 관련 모든 캐시를 제거합니다.
  void invalidateVoteCache(String voteId) {
    final keysToRemove = <String>[];

    for (final key in _requestCache.keys) {
      if (key.endsWith('_$voteId')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _requestCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    logger.d('투표 캐시 무효화 완료: $voteId (${keysToRemove.length}개 항목)');
  }

  /// 전체 캐시 초기화
  void clearAllCache() {
    final cacheSize = _requestCache.length;
    _requestCache.clear();
    _cacheTimestamps.clear();
    logger.d('전체 캐시 초기화 완료: $cacheSize개 항목 제거');
  }

  /// 만료된 캐시 정리
  ///
  /// 주기적으로 호출하여 만료된 캐시 항목들을 제거합니다.
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _requestCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      logger.d('만료된 캐시 정리 완료: ${keysToRemove.length}개 항목 제거');
    }
  }

  /// 캐시 통계 정보 반환
  ///
  /// Returns: 캐시 크기, 만료된 항목 수 등의 정보
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;

    for (final timestamp in _cacheTimestamps.values) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredCount++;
      }
    }

    return {
      'totalCacheSize': _requestCache.length,
      'expiredCount': expiredCount,
      'validCount': _requestCache.length - expiredCount,
      'pendingRequestsCount': _pendingRequests.length,
    };
  }

  /// 캐시가 유효한지 확인
  ///
  /// [cacheKey] 캐시 키
  ///
  /// Returns: 캐시가 존재하고 만료되지 않은 경우 true
  bool _isCacheValid(String cacheKey) {
    if (!_requestCache.containsKey(cacheKey) ||
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();

    return now.difference(timestamp) <= _cacheExpiration;
  }

  /// 캐시 업데이트
  ///
  /// [cacheKey] 캐시 키
  /// [value] 캐시할 값
  void _updateCache(String cacheKey, bool value) {
    _requestCache[cacheKey] = value;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// 리소스 정리
  ///
  /// 서비스 종료 시 호출하여 리소스를 정리합니다.
  void dispose() {
    // 진행 중인 모든 요청 취소
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(const VoteRequestException('서비스가 종료되었습니다.'));
      }
    }

    _pendingRequests.clear();
    clearAllCache();
    logger.d('DuplicatePreventionService 리소스 정리 완료');
  }
}
