import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);
  late int galleryId;

  @override
  Future<PagingController<int, VoteModel>> build(
      {required VoteCategory category, required VoteStatus status}) async {
    fetch(1, 10, 'vote.id', 'DESC',
        category: category.name, status: status.name);
    return _pagingController;
  }

  PagingController<int, VoteModel> get pagingController => _pagingController;

  Future<void> fetch(int page, int limit, String sort, String order,
      {required String category, required String status}) async {
    try {
      final now = DateTime.now().toIso8601String();

      var response;
// status가 'all'이 아닌 경우에만 start_at과 end_at 필드를 기준으로 필터링합니다.
      if (status == 'active') {
        // status가 'active'인 경우, start_at은 현재 시간보다 이전이고 end_at은 현재 시간보다 이후여야 합니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
            // .eq('vote_category', category == 'all' ? '' : category)
            .lt('start_at', now)
            .gt('stop_at', now)
            .count();
      } else if (status == 'end') {
        // status가 'end'인 경우, stop_at은 현재 시간보다 이전이어야 합니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*, mystar_group(*)))')
            // .eq('vote_category', category == 'all' ? '' : category)
            .lt('stop_at', now)
            .count();
      } else {
        // status가 'all'인 경우, 필터링 없이 모든 데이터를 가져옵니다.
        response = await Supabase.instance.client
            .from('vote')
            .select('*, vote_item(*, mystar_member(*))')
            // .eq('vote_category', category == 'all' ? '' : category)
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
        final updatedVoteItems = voteList[i].vote_item.map((item) {
          return item.copyWith(
              mystar_member: item.mystar_member.copyWith(
                  image:
                      'https://cdn-dev.picnic.fan/mystar/member/${item.mystar_member.id}/${item.mystar_member.image}'));
        }).toList();

        voteList[i] = voteList[i].copyWith(vote_item: updatedVoteItems);
      }

      VoteListState voteListState = VoteListState(
        category: category,
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        voteCount: response.count,
        currentPage: 1,
        totalPages: response.count ~/ 10,
        pagingController: _pagingController,
      );

      if (voteListState.currentPage >= voteListState.totalPages) {
        _pagingController.appendLastPage(voteList);
      } else {
        _pagingController.appendPage(voteList, voteListState.currentPage + 1);
      }
    } catch (e, stackTrace) {
      _pagingController.error = e;
      logger.e(e, stackTrace: stackTrace);
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

@reflector
class SortOptionType {
  String sort = '';
  String order = '';

  SortOptionType(this.sort, this.order);
}

@reflector
class VoteListState {
  final String category;
  final int page;
  final int limit;
  final String sort;
  final String order;
  final PagingController<int, VoteModel> pagingController;
  final int voteCount;
  final int currentPage;
  int totalPages;

  VoteListState({
    required this.category,
    required this.page,
    required this.limit,
    required this.sort,
    required this.order,
    required this.pagingController,
    required this.voteCount,
    required this.currentPage,
    required this.totalPages,
  }) {
    totalPages = voteCount ~/ limit;
  }
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
