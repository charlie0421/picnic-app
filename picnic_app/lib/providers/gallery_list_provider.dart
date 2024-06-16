import 'package:picnic_app/models/pic/gallery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'gallery_list_provider.g.dart';

@riverpod
class AsyncGalleryList extends _$AsyncGalleryList {
  @override
  Future<List<GalleryModel>> build() async {
    return _fetchGalleryList();
  }

  Future<List<GalleryModel>> _fetchGalleryList() async {
    final response = await Supabase.instance.client
        .from('gallery')
        .select()
        .order('id', ascending: false);

    List<GalleryModel> galleryList =
        List<GalleryModel>.from(response.map((e) => GalleryModel.fromJson(e)));
    for (var element in galleryList) {
      element = element.copyWith(
          cover:
              'https://cdn-dev.picnic.fan/gallery/${element.id}/${element.cover}');
    }
    return galleryList;
  }
}

@riverpod
class SelectedGalleryId extends _$SelectedGalleryId {
  int selectedGalleryId = 0; // 초기 값이 필요하다면 임시로 할당

  @override
  int build() => selectedGalleryId;

  void setSelectedGalleryId(int id) {
    selectedGalleryId = id;
    state = selectedGalleryId;
  }
}

@riverpod
class AsyncCelebGalleryList extends _$AsyncCelebGalleryList {
  @override
  Future<List<GalleryModel>> build(int celebId) async {
    return _fetchGalleryList(celebId);
  }

  Future<List<GalleryModel>> _fetchGalleryList(celebId) async {
    final response = await Supabase.instance.client
        .from('gallery')
        .select()
        .eq('celeb_id', celebId)
        .order('id', ascending: false);

    List<GalleryModel> galleryList =
        List<GalleryModel>.from(response.map((e) => GalleryModel.fromJson(e)));

    final updatedGalleryList = galleryList.map((gallery) {
      return gallery.copyWith(
          cover:
              'https://cdn-dev.picnic.fan/gallery/${gallery.id}/${gallery.cover}');
    }).toList();
    return updatedGalleryList;
  }
}
