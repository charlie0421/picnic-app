import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/vote.dart';
import 'package:prame_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vote_list_provider.g.dart';

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  final PagingController<int, VoteModel> _pagingController =
      PagingController(firstPageKey: 1);
  late int galleryId;

  @override
  Future<PagingController<int, VoteModel>> build(
      {required String category}) async {
    fetch(category: category);
    return _pagingController;
  }

  PagingController<int, VoteModel> get pagingController => _pagingController;

  Future<void> clearItems() {
    state.value?.itemList?.clear();
    return Future.value();
  }

  Future<void> fetch({required String category}) async {
    try {
      final dio = await authDio(baseUrl: Constants.userApiUrl);
      final response = await dio.get(
        '/vote?category=$category',
      );
      final VoteListModel voteListModel = VoteListModel.fromJson(response.data);
      if (voteListModel.meta.currentPage >= voteListModel.meta.totalPages) {
        _pagingController.appendLastPage(voteListModel.items);
      } else {
        _pagingController.appendPage(
            voteListModel.items, voteListModel.meta.currentPage + 1);
      }
    } catch (e, stackTrace) {
      _pagingController.error = e;
      logger.e(e, stackTrace: stackTrace);
    }
    // logger.d(response.data);
    // return VoteListModel.fromJson(response.data);
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
