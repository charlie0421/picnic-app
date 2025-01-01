import 'package:picnic_app/data/models/pic/celeb.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/celeb_search_provider.g.dart';

@riverpod
class AsyncCelebSearch extends _$AsyncCelebSearch {
  String? _lastQuery;

  @override
  Future<List<CelebModel>?> build() async {
    return [];
  }

  Future<void> searchCeleb(String query) async {
    final response = await supabase
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
    state = const AsyncValue.data([]);
  }
}
