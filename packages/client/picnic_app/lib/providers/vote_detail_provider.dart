import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'vote_detail_provider.g.dart';

@riverpod
class AsyncVoteDetail extends _$AsyncVoteDetail {
  @override
  Future<VoteModel?> build({required int voteId}) async {
    return fetch(voteId: voteId);
  }

  Future<VoteModel?> fetch({required int voteId}) async {
    try {
      final response = await Supabase.instance.client
          .from('vote')
          .select('*, vote_item(*, mystar_member(*)), reward(*))')
          .eq('id', voteId)
          .single();

      logger.i('Vote detail response: $response');
      final voteModel = VoteModel.fromJson(response).copyWith(
          main_image:
              'https://cdn-dev.picnic.fan/vote/$voteId/${response['main_image']}');

      logger.i('Vote detail: $voteModel');

      return voteModel;
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
      final response = await Supabase.instance.client
          .from('vote_item')
          .select('*, mystar_member!left(*,mystar_group(*))')
          .eq('vote_id', voteId)
          .order('vote_total', ascending: false);

      List<VoteItemModel> voteItemList = List<VoteItemModel>.from(
          response.map((e) => VoteItemModel.fromJson(e)));

      for (var element in voteItemList) {
        element.mystar_member.image =
            'https://cdn-dev.picnic.fan/mystar/member/${element.mystar_member.id}/${element.mystar_member.image}';
      }
      return voteItemList;
    } catch (e, stackTrace) {
      logger.e('Failed to load vote item list: $e');
      logger.e('Failed to load vote item list: $stackTrace');
      return [];
    }
  }

  setVoteItem({required int id, required int voteTotal}) async {
    try {
      if (state.value != null) {
        final updatedList = state.value!.map<VoteItemModel>((item) {
          if (item?.id == id) {
            return item?.copyWith(vote_total: voteTotal);
          }
          return item!;
        }).toList();

        state = AsyncValue.data(updatedList);

        //sort by total_vote
        state = AsyncValue.data(state.value!.toList()
          ..sort((a, b) => b!.vote_total.compareTo(a!.vote_total)));

        logger.i('Updated vote item in state: $id with voteTotal: $voteTotal');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to set vote item: $e');
      logger.e('Failed to set vote item: $stackTrace');
    }
  }
}
