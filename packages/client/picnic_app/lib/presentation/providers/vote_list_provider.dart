import 'package:picnic_app/data/models/vote/vote.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/vote_list_provider.g.dart';

enum VoteStatus { all, active, end, upcoming, activeAndUpcoming }

enum VoteCategory { all, birthday, comeback, achieve }

enum VotePortal { vote, pic }

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  @override
  Future<List<VoteModel>> build(int page, int limit, String sort, String order,
      {VotePortal votePortal = VotePortal.vote,
      required VoteStatus status,
      required VoteCategory category}) async {
    return fetch(1, 10, 'id', 'DESC',
        votePortal: votePortal, category: category.name, status: status);
  }

  Future<List<VoteModel>> fetch(int page, int limit, String sort, String order,
      {VotePortal votePortal = VotePortal.vote,
      required String category,
      required VoteStatus status}) async {
    String voteTable = VotePortal.vote == votePortal ? 'vote' : 'pic_vote';
    String voteItemTable =
        VotePortal.vote == votePortal ? 'vote_item' : 'pic_vote_item';

    try {
      PostgrestList response;
      // status가 'all'이 아닌 경우에만 start_at과 end_at 필드를 기준으로 필터링합니다.
      if (status == VoteStatus.active) {
        // status가 'active'인 경우, start_at은 현재 시간보다 이전이고 end_at은 현재 시간보다 이후여야 합니다.
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('start_at', 'now()')
            .gt('stop_at', 'now()')
            .order(sort, ascending: order == 'ASC');
      } else if (status == VoteStatus.end) {
        // status가 'end'인 경우, stop_at은 현재 시간보다 이전이어야 합니다.
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('stop_at', 'now()')
            .order(sort, ascending: order == 'ASC');
      } else if (status == VoteStatus.upcoming) {
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('visible_at', 'now()')
            .gt('start_at', 'now()')
            .order(sort, ascending: order == 'ASC');
      } else if (status == VoteStatus.activeAndUpcoming) {
        // status가 'all'인 경우, 필터링 없이 모든 데이터를 가져옵니다.
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('visible_at', 'now()')
            .gt('stop_at', 'now()')
            .order(sort, ascending: order == 'ASC');
      } else {
        response = await supabase.from(voteTable).select(
            'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))');
      }
      return response.map((e) => VoteModel.fromJson(e)).toList();
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    } finally {}
  }
}

@riverpod
class SortOption extends _$SortOption {
  SortOptionType sortOptions = SortOptionType('id', 'DESC');

  @override
  SortOptionType build() {
    sortOptions = SortOptionType('id', 'DESC');
    return sortOptions;
  }

  void setSortOption(String sort, String order) {
    state = SortOptionType(sort, order);
  }
}

class SortOptionType {
  String sort = '';
  String order = '';

  SortOptionType(this.sort, this.order);
}

@riverpod
class CommentCount extends _$CommentCount {
  @override
  Future<int> build(int articleId) async {
    return 0;
  }

  setCount(int count) {
    state = AsyncValue.data(count);
  }

  increment() {
    state = AsyncValue.data(state.value! + 1);
  }

  decrement() {
    state = AsyncValue.data(state.value! - 1);
  }
}
