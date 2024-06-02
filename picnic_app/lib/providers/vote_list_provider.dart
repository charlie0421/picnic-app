import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'vote_list_provider.g.dart';

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);
  late int galleryId;

  @override
  Future<PagingController<int, VoteModel>> build(
      {required String category}) async {
    fetch(1, 10, 'vote.id', 'DESC', category: category);
    return _pagingController;
  }

  PagingController<int, VoteModel> get pagingController => _pagingController;

  Future<void> fetch(int page, int limit, String sort, String order,
      {required String category}) async {
    try {
      final response = await Supabase.instance.client
          .from('vote')
          .select('*, vote_item(*, mystar_member(*))')
          .eq('vote_category', 'birthday')
          .count();

      logger.i('response.data: $response');

      final List<VoteModel> voteList =
          List<VoteModel>.from(response.data.map((e) => VoteModel.fromJson(e)));

      for (var element in voteList) {
        for (var element in element.vote_item) {
          element.mystar_member.image =
              'https://cdn-dev.picnic.fan/mystar/member/${element.mystar_member.id}/${element.mystar_member.image}';
        }

        logger.i('element: ${element.toJson()}');
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
