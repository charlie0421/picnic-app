import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/compatibility_list_provider.g.dart';

@riverpod
class CompatibilityList extends _$CompatibilityList {
  static const int _pageSize = 10;
  static const String _table = 'compatibility_results';
  int? _artistId;

  @override
  CompatibilityHistoryModel build({int? artistId}) {
    _artistId = artistId;
    return const CompatibilityHistoryModel(
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

  Future<List<CompatibilityModel>> _getHistory({required int page}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    var query = supabase.from(_table).select('''
          *,
          artist(*),
          i18n: compatibility_results_i18n (
            language,
            score,
            score_title,
            compatibility_summary,
            details,
            tips
          )
        ''').eq('user_id', userId);

    if (_artistId != null) {
      query = query.eq('artist_id', _artistId!);
    }

    final response =
        await query.order('created_at', ascending: false).range(from, to);

    return (response as List).map((data) {
      return CompatibilityModel.fromJson(data);
    }).toList();
  }
}
