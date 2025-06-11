import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 중복 방지 전담 서비스 컴포넌트
///
/// 사용자의 중복 신청을 방지하기 위한 서비스입니다.
/// 메모리 캐싱을 통해 효율적인 중복 감지를 지원합니다.
class DuplicatePreventionService {
  final Ref _ref;

  // 메모리 캐시: userId_voteId -> hasRequested
  final Map<String, bool> _cache = {};

  // 캐시 만료 시간 (5분)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // 캐시 타임스탬프: userId_voteId -> timestamp
  final Map<String, DateTime> _cacheTimestamps = {};

  // 진행 중인 요청들을 추적하여 중복 요청 방지
  final Map<String, Completer<bool>> _pendingRequests = {};

  DuplicatePreventionService(this._ref);

  VoteItemRequestRepository get _repository =>
      _ref.read(voteItemRequestRepositoryProvider);

  /// 사용자가 특정 투표에 이미 신청했는지 확인 (캐싱 지원)
  ///
  /// [voteId] 투표 ID
  /// [userId] 사용자 ID
  ///
  /// Returns: 이미 신청했으면 true, 아니면 false
  Future<bool> hasUserRequestedVote(int voteId, String userId) async {
    final cacheKey = '${userId}_$voteId';

    try {
      // 1. 진행 중인 요청이 있는지 확인
      if (_pendingRequests.containsKey(cacheKey)) {
        return await _pendingRequests[cacheKey]!.future;
      }

      // 2. 캐시 확인
      if (_isCacheValid(cacheKey)) {
        logger.d('캐시에서 중복 신청 정보 반환: $cacheKey');
        return _cache[cacheKey]!;
      }

      // 3. 새로운 요청 시작
      final completer = Completer<bool>();
      _pendingRequests[cacheKey] = completer;

      try {
        // 4. 데이터베이스 조회
        final hasRequested = await _repository.hasUserRequestedArtist(
          voteId,
          0, // 특정 아티스트가 아닌 전체 투표 확인
          userId,
        );

        // 5. 캐시 업데이트
        _updateCache(cacheKey, hasRequested);

        // 6. 결과 반환
        completer.complete(hasRequested);
        return hasRequested;
      } catch (e) {
        completer.completeError(e);
        rethrow;
      } finally {
        _pendingRequests.remove(cacheKey);
      }
    } catch (e) {
      logger.e('중복 신청 확인 중 오류 발생', error: e);
      throw VoteRequestException('중복 신청 확인에 실패했습니다: ${e.toString()}');
    }
  }

  /// 사용자가 이미 해당 아티스트에 대해 신청했는지 확인
  Future<bool> hasUserRequestedArtist({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    try {
      return await _repository.hasUserRequestedArtist(
        voteId,
        artistId,
        userId,
      );
    } catch (e) {
      logger.e('중복 신청 확인 중 오류 발생', error: e);
      return false;
    }
  }

  /// 캐시가 유효한지 확인
  bool _isCacheValid(String cacheKey) {
    if (!_cache.containsKey(cacheKey) ||
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();

    return now.difference(timestamp) < _cacheExpiration;
  }

  /// 캐시 업데이트
  void _updateCache(String cacheKey, bool hasRequested) {
    _cache[cacheKey] = hasRequested;
    _cacheTimestamps[cacheKey] = DateTime.now();

    logger.d('캐시 업데이트: $cacheKey = $hasRequested');
  }

  /// 캐시 무효화 (신청 후 호출)
  void invalidateCache(int voteId, String userId) {
    final cacheKey = '${userId}_$voteId';
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);

    logger.d('캐시 무효화: $cacheKey');
  }

  /// 전체 캐시 클리어
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    logger.d('전체 캐시 클리어');
  }
}
