import 'package:picnic_app/models/pic/gallery.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/gallery_list_provider.g.dart';

@riverpod
class AsyncGalleryList extends _$AsyncGalleryList {
  @override
  Future<List<GalleryModel>> build() async {
    return _fetchGalleryList();
  }

  Future<List<GalleryModel>> _fetchGalleryList() async {
    final response =
        await supabase.from('gallery').select().order('id', ascending: false);

    List<GalleryModel> galleryList =
        List<GalleryModel>.from(response.map((e) => GalleryModel.fromJson(e)));
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
    final response = await supabase
        .from('gallery')
        .select()
        .eq('celeb_id', celebId)
        .order('id', ascending: false);

    List<GalleryModel> galleryList =
        List<GalleryModel>.from(response.map((e) => GalleryModel.fromJson(e)));

    return galleryList;
  }
}
