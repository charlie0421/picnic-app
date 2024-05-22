import 'package:picnic_app/constants.dart';
import 'package:picnic_app/main.dart';
import 'package:picnic_app/models/prame/gallery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_list_provider.g.dart';

@riverpod
class AsyncGalleryList extends _$AsyncGalleryList {
  @override
  Future<List<GalleryModel>> build() async {
    return _fetchGalleryList();
  }

  Future<List<GalleryModel>> _fetchGalleryList() async {
    final response = await supabase.from('gallery').select();
    logger.w('gallery: $response');
    List<GalleryModel> galleryList =
        List<GalleryModel>.from(response.map((e) => GalleryModel.fromJson(e)));
    galleryList.forEach((element) {
      element.cover =
          'https://cdn-dev.picnic.fan/gallery/${element.id}/${element.cover}';
    });
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
