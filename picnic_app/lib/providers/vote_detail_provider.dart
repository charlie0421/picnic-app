import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'vote_detail_provider.g.dart';

@riverpod
class AsyncVoteDetail extends _$AsyncVoteDetail {
  @override
  Future<VoteModel?> build({required int voteId}) async {
    return fetch(voteId: voteId);
  }

  Future<VoteModel?> fetch({required int voteId}) async {
    try {
      final response = await supabase
          .from('vote')
          .select(
              '*, vote_item(*, artist(*, artist_group(*)), artist_group(*)), reward(*)')
          .eq('id', voteId)
          .single();

      // logger.i('Vote detail response: $response');

      final now = DateTime.now().toUtc();

      // Add a new field to indicate if the current time is after end_at
      response['is_ended'] = now.isAfter(DateTime.parse(response['stop_at']));
      response['is_upcoming'] =
          now.isBefore(DateTime.parse(response['start_at']));

      return VoteModel.fromJson(response);
    } catch (e, s) {
      logger.e('Failed to load vote detail: $e');
      logger.e('Failed to load vote detail: $s');
    }
    return null;
  }
}

@riverpod
class AsyncVoteItemList extends _$AsyncVoteItemList {
  @override
  FutureOr<List<VoteItemModel?>> build({required int voteId}) async {
    return fetch(voteId: voteId);
  }

  FutureOr<List<VoteItemModel?>> fetch({required int voteId}) async {
    try {
      final response = await supabase
          .from('vote_item')
          .select('*, artist(*,artist_group(*)), artist_group(*)')
          .eq('vote_id', voteId)
          .order('vote_total', ascending: false);

      logger.i('Vote item list response: $response');

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
            item = item.copyWith(vote_total: voteTotal);
          }
          return item!;
        }).toList();

        state = AsyncValue.data(updatedList);

        //sort by total_vote
        state = AsyncValue.data(state.value!.toList()
          ..sort((a, b) => b!.vote_total.compareTo(a!.vote_total)));

        logger.i('Updated vote item in state: $id with voteTotal: $voteTotal');
      }
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
    }
  }
}
