import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/community/compatibility_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:picnic_app/repositories/compatibility_repository.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';

part 'compatibility_history_provider.g.dart';

@riverpod
class CompatibilityHistory extends _$CompatibilityHistory {
  static const int _pageSize = 10;
  static const String _table = 'compatibility_results';

  @override
  CompatibilityHistoryModel build() {
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
      final items = await ref
          .read(compatibilityRepositoryProvider)
          .getCompatibilityHistory(0, _pageSize);
      state = state.copyWith(
        items: items,
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final items = await ref
          .read(compatibilityRepositoryProvider)
          .getCompatibilityHistory(state.items.length, _pageSize);

      state = state.copyWith(
        items: [...state.items, ...items],
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<List<CompatibilityModel>> getCompatibilityHistory({
    required int page,
    required int pageSize,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await supabase
          .from(_table)
          .select('*, artist(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map((data) => _mapToCompatibilityModel(data))
          .toList();
    } catch (e, stackTrace) {
      logger.e('Failed to get compatibility history',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to get compatibility history: $e');
    }
  }

  CompatibilityModel _mapToCompatibilityModel(Map<String, dynamic> data) {
    final artistData = data['artist'] as Map<String, dynamic>;

    return CompatibilityModel(
      id: data['id'],
      userId: data['user_id'],
      artist: ArtistModel.fromJson(artistData),
      birthDate: DateTime.parse(data['user_birth_date']),
      birthTime: data['birth_time'],
      gender: data['gender'],
      status: CompatibilityStatusX.fromJson(data['status']),
      compatibilityScore: data['compatibility_score'],
      compatibilitySummary: data['compatibility_summary'],
      style: data['details'] != null && data['details']['style'] != null
          ? StyleDetails.fromJson(data['details']['style'])
          : null,
      activities:
          data['details'] != null && data['details']['activities'] != null
              ? ActivitiesDetails.fromJson(data['details']['activities'])
              : null,
      tips: data['tips'] != null ? List<String>.from(data['tips']) : null,
      errorMessage: data['error_message'],
      createdAt: DateTime.parse(data['created_at']),
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'])
          : null,
    );
  }
}
