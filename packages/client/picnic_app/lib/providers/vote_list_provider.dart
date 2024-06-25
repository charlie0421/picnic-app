import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'vote_list_provider.g.dart';

enum VoteStatus { all, active, end }

enum VoteCategory { all, birthday }

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  @override
  Future<VoteListModel> build(int page, int limit, String sort, String order,
      {required VoteStatus status, required VoteCategory category}) async {
    return fetch(1, 10, 'vote.id', 'DESC',
        category: category.name, status: status.name);
  }

  Future<VoteListModel> fetch(int page, int limit, String sort, String order,
      {required String category, required String status}) async {
    try {
      final now = DateTime.now().toIso8601String();

      PostgrestResponse<PostgrestList> response;
// status가 'all'이 아닌 경우에만 start_at과 end_at 필드를 기준으로 필터링합니다.
      if (status == 'active') {
        // status가 'active'인 경우, start_at은 현재 시간보다 이전이고 end_at은 현재 시간보다 이후여야 합니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
            // .eq('vote_category', category == 'all' ? '' : category)
            .lt('start_at', now)
            .gt('stop_at', now)
            .order(sort, ascending: order == 'ASC')
            .count();
      } else if (status == 'end') {
        // status가 'end'인 경우, stop_at은 현재 시간보다 이전이어야 합니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
            // .eq('vote_category', category == 'all' ? '' : category)
            .lt('stop_at', now)
            .order(sort, ascending: order == 'ASC')
            .count();
      } else {
        // status가 'all'인 경우, 필터링 없이 모든 데이터를 가져옵니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*))')
            // .eq('vote_category', category == 'all' ? '' : category)
            .order(sort, ascending: order == 'ASC')
            .count();
      }
      // final response = await Supabase.instance.client
      //     .from('vote')
      //     .select('*, vote_item(*, mystar_member(*))')
      //     .eq('vote_category', category == 'all' ? '' : category)
      //     .eq('status', status == 'all' ? '' : status)
      //     .count();

      final List<VoteModel> voteList =
          List<VoteModel>.from(response.data.map((e) => VoteModel.fromJson(e)));

      for (var i = 0; i < voteList.length; i++) {
        final updatedVoteItems = voteList[i].vote_item?.map((item) {
          return item.copyWith(
              mystar_member: item.mystar_member.copyWith(
                  image:
                      'https://cdn-dev.picnic.fan/mystar/member/${item.mystar_member.id}/${item.mystar_member.image}'));
        }).toList();

        voteList[i] = voteList[i].copyWith(vote_item: updatedVoteItems);
      }

      return VoteListModel.fromJson({
        'items': voteList,
        'meta': {
          'totalItems': response.count,
          'currentPage': page,
          'itemCount': response.data.length,
          'itemsPerPage': limit,
          'totalPages': (response.count + 1) ~/ limit,
        }
      });
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);
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

@reflector
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
