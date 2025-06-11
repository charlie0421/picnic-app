import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

/// 투표 아이템 신청 서비스 Provider
final voteItemRequestServiceProvider = Provider<VoteItemRequestService>((ref) {
  return VoteItemRequestService(ref);
});

/// 투표 아이템 신청 서비스
class VoteItemRequestService {
  final Ref _ref;

  VoteItemRequestService(this._ref);

  VoteItemRequestRepository get _repository =>
      _ref.read(voteItemRequestRepositoryProvider);
  DuplicatePreventionService get _duplicateService =>
      DuplicatePreventionService(_ref);

  /// 투표 아이템 신청
  Future<bool> submitVoteItemRequest({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    try {
      // 중복 신청 확인
      final hasRequested = await _duplicateService.hasUserRequestedArtist(
        voteId: voteId,
        artistId: artistId,
        userId: userId,
      );

      if (hasRequested) {
        logger.w(
            '이미 신청한 아티스트입니다: voteId=$voteId, artistId=$artistId, userId=$userId');
        return false;
      }

      // 신청 처리
      await _repository.createVoteItemRequestUser(
        voteId: voteId,
        artistId: artistId,
        userId: userId,
      );

      // 캐시 무효화
      _duplicateService.invalidateCache(voteId, userId);

      logger.i(
          '투표 아이템 신청 완료: voteId=$voteId, artistId=$artistId, userId=$userId');
      return true;
    } catch (e) {
      logger.e('투표 아이템 신청 중 오류 발생', error: e);
      return false;
    }
  }

  /// 사용자의 투표 아이템 신청 목록 조회
  Future<List<Map<String, dynamic>>> getUserVoteItemRequests(
      String userId) async {
    try {
      return await _repository.getUserVoteItemRequests(userId);
    } catch (e) {
      logger.e('사용자 투표 아이템 신청 목록 조회 중 오류 발생', error: e);
      return [];
    }
  }

  /// 아티스트 신청 (기존 메서드와 호환성을 위해)
  Future<bool> submitArtistApplication({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    return await submitVoteItemRequest(
      voteId: voteId,
      artistId: artistId,
      userId: userId,
    );
  }
}
