import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'vote_list_provider.dart';

part '../../generated/providers/vote_detail_provider.g.dart';

@riverpod
class AsyncVoteDetail extends _$AsyncVoteDetail {
  @override
  Future<VoteModel?> build(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  Future<VoteModel?> fetch(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    final voteTable = votePortal == VotePortal.vote ? 'vote' : 'pic_vote';
    final voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';

    try {
      final response = await supabase
          .from(voteTable)
          .select(
              'id, main_image, title, start_at, stop_at, visible_at, vote_category, $voteItemTable(*, artist(*, artist_group(*)), artist_group(*)), reward(*)')
          .eq('id', voteId)
          .single();

      final now = DateTime.now().toUtc();

      // Add a new field to indicate if the current time is after end_at
      response['is_ended'] = now.isAfter(DateTime.parse(response['stop_at']));
      response['is_upcoming'] =
          now.isBefore(DateTime.parse(response['start_at']));

      return VoteModel.fromJson(response);
    } catch (e, s) {
      logger.e('Failed to load vote detail: $e', stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
    }
    return null;
  }
}

@riverpod
class AsyncVoteItemList extends _$AsyncVoteItemList {
  @override
  FutureOr<List<VoteItemModel?>> build(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  FutureOr<List<VoteItemModel?>> fetch(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    final voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';
    try {
      final response = await supabase
          .from(voteItemTable)
          .select(
              'id, vote_id, vote_total, artist(*,artist_group(*)), artist_group(*)')
          .eq('vote_id', voteId)
          .filter('deleted_at', 'is', null)
          .order('vote_total', ascending: false);

      List<VoteItemModel> voteItemList = List<VoteItemModel>.from(
          response.map((e) => VoteItemModel.fromJson(e)));

      state = AsyncValue.data(voteItemList);

      return voteItemList;
    } catch (e, s) {
      logger.e(s, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );

      return [];
    }
  }

  setVoteItem({required int id, required int voteTotal}) async {
    try {
      if (state.value != null) {
        final updatedList = state.value!.map<VoteItemModel>((item) {
          if (item != null && item.id == id) {
            item = item.copyWith(voteTotal: voteTotal);
          }
          return item!;
        }).toList();

        state = AsyncValue.data(updatedList);

        //sort by total_vote
        state = AsyncValue.data(state.value!.toList()
          ..sort((a, b) => b!.voteTotal!.compareTo(a!.voteTotal!)));

        logger.i('Updated vote item in state: $id with voteTotal: $voteTotal');
      }
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }
}

@riverpod
Future<List<VoteAchieve>?> fetchVoteAchieve(ref, {required int voteId}) async {
  try {
    final response = await supabase
        .from('vote_achieve')
        .select('id, vote_id, reward_id, order, amount, reward(*), vote(*)')
        .eq('vote_id', voteId)
        .order('order', ascending: true);

    return response.map<VoteAchieve>((e) => VoteAchieve.fromJson(e)).toList();
  } catch (e, s) {
    logger.e(s, stackTrace: s);
    Sentry.captureException(
      e,
      stackTrace: s,
    );

    return null;
  }
}
