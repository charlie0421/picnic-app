import 'package:picnic_app/main.dart';
import 'package:picnic_app/models/prame/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celeb_list_provider.g.dart';

@riverpod
class AsyncCelebList extends _$AsyncCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    return _fetchCelebList();
  }

  Future<List<CelebModel>?> _fetchCelebList() async {
    final response = await supabase.from('celeb').select();
    final List<CelebModel> celebList =
        List<CelebModel>.from(response.map((e) => CelebModel.fromJson(e)));
    celebList.forEach((element) {
      element.thumbnail =
          'https://cdn-dev.picnic.fan/celeb/${element.id}/${element.thumbnail}';
    });
    return celebList;
  }

  Future<void> addBookmark(CelebModel celeb) async {
    final response = await supabase
        .from('celeb_bookmark')
        .insert({'celeb_id': celeb.id, 'user_id': 1});

    state = AsyncValue.data(response);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }

  Future<void> removeBookmark(CelebModel celeb) async {
    final response = await supabase
        .from('celeb_bookmark')
        .delete()
        .eq('celeb_id', celeb.id)
        .eq('user_id', 1);

    state = AsyncValue.data(response);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }
}

@riverpod
class AsyncMyCelebList extends _$AsyncMyCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    return fetchMyCelebList();
  }

  Future<List<CelebModel>?> fetchMyCelebList() async {
    final response = await supabase
        .from('celeb_bookmark')
        .select('celeb_id')
        .eq('user_id', 1);

    return List<CelebModel>.from(response.map((e) => CelebModel.fromJson(e)));
  }
}

@riverpod
class SelectedCeleb extends _$SelectedCeleb {
  CelebModel? selectedCeleb; // 초기 값이 필요하다면 임시로 할당

  @override
  CelebModel? build() => selectedCeleb;

  void setSelectedCeleb(CelebModel? celebModel) {
    state = celebModel;
  }
}
