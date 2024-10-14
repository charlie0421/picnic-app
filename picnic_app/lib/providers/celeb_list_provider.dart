import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'celeb_list_provider.g.dart';

@riverpod
class AsyncCelebList extends _$AsyncCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    return _fetchCelebList();
  }

  Future<List<CelebModel>?> _fetchCelebList() async {
    final response =
        await supabase.from('celeb').select().order('id', ascending: true);

    final List<CelebModel> celebList =
        List<CelebModel>.from(response.map((e) => CelebModel.fromJson(e)));

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

@Riverpod(keepAlive: true)
class AsyncMyCelebList extends _$AsyncMyCelebList {
  @override
  Future<List<CelebModel>?> build() async {
    logger.i('fetchMyCelebList');
    return fetchMyCelebList();
  }

  Future<List<CelebModel>?> fetchMyCelebList() async {
    try {
      if (supabase.auth.currentUser == null) {
        return null;
      }

      final response = await supabase
          .from('celeb_user')
          .select('celeb(*)')
          .eq('user_id', supabase.uid.toString())
          .order('celeb_id', ascending: true);
      List<CelebModel> celebList = List<CelebModel>.from(
          response.map((e) => CelebModel.fromJson(e['celeb'])));

      state = AsyncValue.data(celebList);

      return celebList;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      logger.e(e, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
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
