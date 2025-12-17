import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/goonghap_list_provider.g.dart';

@riverpod
class GoonghapList extends _$GoonghapList {
  static const int _pageSize = 10;
  static const String _table = 'goonghap_results';
  int? _artistId;

  @override
  GoonghapHistoryModel build({int? artistId}) {
    _artistId = artistId;
    return const GoonghapHistoryModel(
      items: [],
      hasMore: true,
      isLoading: false,
    );
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final items = await _getHistory(page: 0);
      state = state.copyWith(
        items: items,
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final page = (state.items.length / _pageSize).floor();
      final items = await _getHistory(page: page);

      state = state.copyWith(
        items: [...state.items, ...items],
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e, s) {
      logger.e('Error', error: e, stackTrace: s);
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<List<GoonghapModel>> _getHistory({required int page}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return []; // 비로그인 시 빈 목록 반환

    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    // 리스트에서는 details, tips 불필요 (상세 페이지에서만 보안 RPC로 조회)
    var query = supabase.from(_table).select('''
          *,
          artist(*),
          i18n: goonghap_results_i18n (
            language,
            score,
            score_title,
            goonghap_summary
          )
        ''').eq('user_id', userId);

    if (_artistId != null) {
      query = query.eq('artist_id', _artistId!);
    }

    final response =
        await query.order('created_at', ascending: false).range(from, to);

    return (response as List).map((data) {
      return GoonghapModel.fromJson(data);
    }).toList();
  }
}
