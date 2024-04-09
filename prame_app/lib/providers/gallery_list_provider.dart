import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/gallery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_list_provider.g.dart';

@riverpod
class AsyncGalleryList extends _$AsyncGalleryList {
  @override
  Future<GalleryListModel> build({required int celebId}) async {
    return _fetchGalleryList(celebId: celebId);
  }

  Future<GalleryListModel> _fetchGalleryList({required int celebId}) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = celebId != 0
        ? await dio.get('/gallery/celeb/$celebId')
        : await dio.get('/gallery');
    return GalleryListModel.fromJson(response.data);
  }
}
