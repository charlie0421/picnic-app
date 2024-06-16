import 'package:picnic_app/models/pic/article_image.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'article_image_list_provider.g.dart';

@riverpod
class AsyncArticleImageList extends _$AsyncArticleImageList {
  @override
  Future<List<ArticleImageModel>> build({required int galleryId}) async {
    return _fetchGalleryImageList(galleryId: galleryId);
  }

  Future<List<ArticleImageModel>> _fetchGalleryImageList(
      {required int galleryId}) async {
    final response = await Supabase.instance.client
        .from('article')
        .select()
        .eq('gallery_id', galleryId);
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
