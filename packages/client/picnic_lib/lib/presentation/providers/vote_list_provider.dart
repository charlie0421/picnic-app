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
  List<VoteModel> _allItems = [];

  @override
  Future<List<VoteModel>> build(int page, int limit, String sort, String order,
      {VotePortal votePortal = VotePortal.vote,
      required VoteStatus status,
      required VoteCategory category}) async {
    // 첫 페이지이거나 아직 데이터가 없는 경우에만 전체 데이터를 가져옴
    if (page == 1 || _allItems.isEmpty) {
      _allItems = await _fetchAll(sort, order,
          votePortal: votePortal, category: category.name, status: status);
    }

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= _allItems.length) {
      return []; // 더 이상 아이템이 없음
    }

    // 현재 페이지의 아이템들 반환
    return _allItems
        .sublist(
          startIndex,
          endIndex > _allItems.length ? _allItems.length : endIndex,
        )
        .toList();
  }

  Future<List<VoteModel>> _fetchAll(String sort, String order,
      {required VotePortal votePortal,
      required String category,
      required VoteStatus status}) async {
    String voteTable = VotePortal.vote == votePortal ? 'vote' : 'pic_vote';
    String voteItemTable =
        VotePortal.vote == votePortal ? 'vote_item' : 'pic_vote_item';

    try {
      PostgrestList response;
      if (status == VoteStatus.active) {
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('start_at', 'now()')
            .gt('stop_at', 'now()')
            .order(sort, ascending: order == 'ASC');
      } else if (status == VoteStatus.end) {
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
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .lt('visible_at', 'now()')
            .gt('stop_at', 'now()')
            .order('stop_at', ascending: true);
      } else {
        response = await supabase
            .from(voteTable)
            .select(
                'id,title,start_at,stop_at, visible_at,$voteItemTable(*, artist(id,name,image, artist_group(id,name,image)), artist_group(id,name,image))')
            .order(sort, ascending: order == 'ASC');
      }

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
