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
          .select('*, vote_item(*, mystar_member(*))')
          .eq('id', voteId)
          .single();

      return VoteModel.fromJson(response);
    } catch (e) {
      logger.e('Failed to load vote detail: $e');
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
          .eq('vote_id', voteId);

      logger.i('response.data: $response');

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
}
