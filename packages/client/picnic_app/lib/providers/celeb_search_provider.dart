import 'package:picnic_app/models/prame/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'celeb_search_provider.g.dart';

@riverpod
class AsyncCelebSearch extends _$AsyncCelebSearch {
  String? _lastQuery;

  @override
  Future<List<CelebModel>?> build() async {
    return [];
  }

  Future<void> searchCeleb(String query) async {
    final response = await Supabase.instance.client
        .from('celeb')
        .select()
        .ilike('name_ko', '%$query%')
        .or('name_en')
        .range(0, 10);

    state =
        AsyncValue.data(response.map((e) => CelebModel.fromJson(e)).toList());
  }

  Future<void> repeatSearch() async {
    if (_lastQuery == null) {
      return;
    }
    await searchCeleb(_lastQuery!);
  }

  Future<void> reset() async {
    state = AsyncValue.data([]);
  }
}
