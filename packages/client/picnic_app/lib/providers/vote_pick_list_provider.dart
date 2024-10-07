import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote_pick.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'vote_pick_list_provider.g.dart';

@riverpod
class AsyncVotePickList extends _$AsyncVotePickList {
  @override
  Future<VotePickListModel> build(
      int page, int limit, String sort, String order) async {
    return fetch(1, limit, 'vote_pick.id', 'DESC');
  }

  Future<VotePickListModel> fetch(
      int page, int limit, String sort, String order) async {
    try {
      final response = await supabase
          .from('vote_pick')
          .select('*, vote(*), vote_item(*, mystar_member(*, mystar_group(*)))')
          .order(sort, ascending: order == 'ASC')
          .limit(limit)
          .count();

      final meta = {
        'totalItems': response.count,
        'currentPage': page,
        'itemCount': response.data.length,
        'itemsPerPage': limit,
        'totalPages': (limit + 1) / response.count,
      };

      logger.d(meta);

      return VotePickListModel.fromJson({'items': response.data, 'meta': meta});
    } catch (e, s) {
      logger.e(e, stackTrace: s);
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
