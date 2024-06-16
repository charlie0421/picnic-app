import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'celeb_list_provider.g.dart';

@riverpod
class AsyncCelebList extends _$AsyncCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    return _fetchCelebList();
  }

  Future<List<CelebModel>?> _fetchCelebList() async {
    final response = await Supabase.instance.client
        .from('celeb')
        .select()
        .order('id', ascending: true);

    final List<CelebModel> celebList =
        List<CelebModel>.from(response.map((e) => CelebModel.fromJson(e)));

    final updatedCelebList = celebList.map((celeb) {
      return celeb = celeb.copyWith(
          thumbnail:
              'https://cdn-dev.picnic.fan/celeb/${celeb.id}/${celeb.thumbnail}');
    }).toList();

    return updatedCelebList;
  }

  Future<void> addBookmark(CelebModel celeb) async {
    final response = await Supabase.instance.client
        .from('celeb_bookmark')
        .insert({'celeb_id': celeb.id, 'user_id': 1});

    state = AsyncValue.data(response);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }

  Future<void> removeBookmark(CelebModel celeb) async {
    final response = await Supabase.instance.client
        .from('celeb_bookmark')
        .delete()
        .eq('celeb_id', celeb.id)
        .eq('user_id', 1);

    state = AsyncValue.data(response);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }
}

@Riverpod(keepAlive: true)
class AsyncMyCelebList extends _$AsyncMyCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    logger.i('fetchMyCelebList');
    return fetchMyCelebList();
  }

  Future<List<CelebModel>?> fetchMyCelebList() async {
    try {
      if (Supabase.instance.client.auth.currentUser == null) {
        return null;
      }

      final response = await Supabase.instance.client
          .from('celeb_user')
          .select('celeb(*)')
          .eq('user_id', Supabase.instance.client.uid.toString())
          .order('celeb_id', ascending: true);
      List<CelebModel> celebList = List<CelebModel>.from(
          response.map((e) => CelebModel.fromJson(e['celeb'])));

      final updatedCelebList = celebList.map((celeb) {
        return celeb = celeb.copyWith(
            thumbnail:
                'https://cdn-dev.picnic.fan/celeb/${celeb.id}/${celeb.thumbnail}');
      }).toList();

      state = AsyncValue.data(updatedCelebList);

      return updatedCelebList;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      logger.i('fetchMyCelebList error: $e');
      logger.i('fetchMyCelebList stackTrace: $stackTrace');
    }
    return null;
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
