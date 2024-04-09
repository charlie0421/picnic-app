import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/gallery_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_image_list_provider.g.dart';

@riverpod
class AsyncGalleryImageList extends _$AsyncGalleryImageList {
  @override
  Future<GalleryImageListModel> build({required int galleryId}) async {
    return _fetchGalleryImageList(galleryId: galleryId);
  }

  Future<GalleryImageListModel> _fetchGalleryImageList(
      {required int galleryId}) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/gallery/images/$galleryId');

    return GalleryImageListModel.fromJson(response.data);
  }
}
