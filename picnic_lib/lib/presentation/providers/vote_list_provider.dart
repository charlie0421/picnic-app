import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/vote_list_provider.g.dart';

enum VoteStatus { all, active, end, upcoming, activeAndUpcoming }

enum VoteCategory { all, birthday, comeback, achieve }

enum VotePortal { vote, pic }

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  @override
  Future<List<VoteModel>> build(
      int page, int limit, String sort, String order, String area,
      {VotePortal votePortal = VotePortal.vote,
      required VoteStatus status,
      required VoteCategory category}) async {
    return await _fetchPage(
      page: page,
      limit: limit,
      sort: sort,
      order: order,
      votePortal: votePortal,
      category: category.name,
      status: status,
      area: area,
    );
  }

  Future<List<VoteModel>> _fetchPage({
    required int page,
    required int limit,
    required String sort,
    required String order,
    required VotePortal votePortal,
    required String category,
    required VoteStatus status,
    required String area,
  }) async {
    String voteTable = votePortal == VotePortal.vote ? 'vote' : 'pic_vote';
    String voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';

    try {
      PostgrestList response;
      final offset = (page - 1) * limit;

      var query = supabase
          .from(voteTable)
          .select(
              'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
          .eq('area', area)
          .filter('deleted_at', 'is', null);

      if (status == VoteStatus.active) {
        query = query
            .lt('visible_at', 'now()')
            .lt('start_at', 'now()')
            .gt('stop_at', 'now()');
      } else if (status == VoteStatus.end) {
        query = query.lt('stop_at', 'now()');
      } else if (status == VoteStatus.upcoming) {
        query = query.lt('visible_at', 'now()').gt('start_at', 'now()');
      } else if (status == VoteStatus.activeAndUpcoming) {
        query = query.lt('visible_at', 'now()').gt('stop_at', 'now()');
        sort = 'stop_at';
        order = 'ASC';
      }

      response = await query
          .order(sort, ascending: order == 'ASC')
          .range(offset, offset + limit - 1);

      return response.map((e) => VoteModel.fromJson(e)).toList();
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
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
