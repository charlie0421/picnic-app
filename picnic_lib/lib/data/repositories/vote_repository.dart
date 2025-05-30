import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/repositories/offline_first_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class VoteRepository extends OfflineFirstRepository<VoteModel> {
  @override
  String get tableName => 'votes';

  @override
  VoteModel fromJson(Map<String, dynamic> json) => VoteModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(VoteModel model) => model.toJson();

  @override
  String getId(VoteModel model) => model.id.toString();

  /// 활성 투표들을 가져옵니다
  Future<List<VoteModel>> getActiveVotes() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final results = await getAll(
        where: 'start_at <= ? AND stop_at >= ? AND is_ended = 0',
        whereArgs: [now, now],
        orderBy: 'start_at DESC',
      );
      
      logger.d('Fetched ${results.length} active votes');
      return results;
    } catch (e, s) {
      logger.e('Error fetching active votes', error: e, stackTrace: s);
      return [];
    }
  }

  /// 예정된 투표들을 가져옵니다
  Future<List<VoteModel>> getUpcomingVotes() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final results = await getAll(
        where: 'start_at > ? AND is_upcoming = 1',
        whereArgs: [now],
        orderBy: 'start_at ASC',
      );
      
      logger.d('Fetched ${results.length} upcoming votes');
      return results;
    } catch (e, s) {
      logger.e('Error fetching upcoming votes', error: e, stackTrace: s);
      return [];
    }
  }

  /// 종료된 투표들을 가져옵니다
  Future<List<VoteModel>> getEndedVotes() async {
    try {
      final results = await getAll(
        where: 'is_ended = 1',
        orderBy: 'stop_at DESC',
      );
      
      logger.d('Fetched ${results.length} ended votes');
      return results;
    } catch (e, s) {
      logger.e('Error fetching ended votes', error: e, stackTrace: s);
      return [];
    }
  }

  /// 카테고리별 투표들을 가져옵니다
  Future<List<VoteModel>> getVotesByCategory(String category) async {
    try {
      final results = await getAll(
        where: 'vote_category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
      
      logger.d('Fetched ${results.length} votes for category: $category');
      return results;
    } catch (e, s) {
      logger.e('Error fetching votes by category', error: e, stackTrace: s);
      return [];
    }
  }

  /// 투표 상태를 업데이트합니다
  Future<VoteModel?> updateVoteStatus(int voteId, {bool? isEnded, bool? isUpcoming}) async {
    try {
      final vote = await getById(voteId.toString());
      if (vote == null) {
        logger.w('Vote not found: $voteId');
        return null;
      }

      final updatedVote = vote.copyWith(
        isEnded: isEnded,
        isUpcoming: isUpcoming,
      );

      return await update(updatedVote);
    } catch (e, s) {
      logger.e('Error updating vote status', error: e, stackTrace: s);
      return null;
    }
  }
} 