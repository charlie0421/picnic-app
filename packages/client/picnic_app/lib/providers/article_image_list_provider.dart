import 'package:picnic_app/models/pic/article_image.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/article_image_list_provider.g.dart';

@riverpod
class AsyncArticleImageList extends _$AsyncArticleImageList {
  @override
  Future<List<ArticleImageModel>> build({required int galleryId}) async {
    return _fetchGalleryImageList(galleryId: galleryId);
  }

  Future<List<ArticleImageModel>> _fetchGalleryImageList(
      {required int galleryId}) async {
    final response =
        await supabase.from('article').select().eq('gallery_id', galleryId);
    final List<ArticleImageModel> articleImageList =
        List<ArticleImageModel>.from(
            response.map((e) => ArticleImageModel.fromJson(e)));
    for (var i = 0; i < articleImageList.length; i++) {
      articleImageList[i] = articleImageList[i].copyWith(
          image:
              'https://cdn-dev.picnic.fan/article/${articleImageList[i].id}/${articleImageList[i].image}');
    }
    return articleImageList;
  }
}
