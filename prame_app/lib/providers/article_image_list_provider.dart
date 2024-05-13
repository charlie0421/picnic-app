import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/prame/article_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'article_image_list_provider.g.dart';

@riverpod
class AsyncArticleImageList extends _$AsyncArticleImageList {
  @override
  Future<ArticleImageListModel> build({required int galleryId}) async {
    return _fetchGalleryImageList(galleryId: galleryId);
  }

  Future<ArticleImageListModel> _fetchGalleryImageList(
      {required int galleryId}) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/gallery/images/$galleryId');

    return ArticleImageListModel.fromJson(response.data);
  }
}
