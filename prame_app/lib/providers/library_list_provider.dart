import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/prame/gallery.dart';
import 'package:prame_app/models/prame/library.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_list_provider.g.dart';

@riverpod
class AsyncLibraryList extends _$AsyncLibraryList {
  @override
  Future<LibraryListModel> build() async {
    return _fetchGalleryList();
  }

  Future<LibraryListModel> _fetchGalleryList() async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/library/me');
    return LibraryListModel.fromJson(response.data);
  }

  Future<void> addImageToLibrary(int libraryId, int imageId) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    try {
      final response = await dio.post('/library',
          queryParameters: {'imageId': imageId, 'libraryId': libraryId});
      if (response.statusCode == 201) {
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e, stacktrace) {
      logger.e(e, stackTrace: stacktrace);
    }
  }
}
