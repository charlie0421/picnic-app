import 'package:picnic_app/models/prame/article_image.dart';
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
    articleImageList.forEach((element) {
      element.image =
          'https://cdn-dev.picnic.fan/article/${element.id}/${element.image}';
    });

    return articleImageList;
  }
}
