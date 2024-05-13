import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/prame/gallery.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_list_provider.g.dart';

@riverpod
class AsyncGalleryList extends _$AsyncGalleryList {
  @override
  Future<GalleryListModel> build() async {
    return _fetchGalleryList();
  }

  Future<GalleryListModel> _fetchGalleryList() async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/gallery');
    return GalleryListModel.fromJson(response.data);
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
