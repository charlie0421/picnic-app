import 'package:picnic_app/models/pic/library.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/library_list_provider.g.dart';

@riverpod
class AsyncLibraryList extends _$AsyncLibraryList {
  @override
  Future<List<LibraryModel>?> build() async {
    return _fetchGalleryList();
  }

  Future<List<LibraryModel>?> _fetchGalleryList() async {
    final response = await supabase.from('library').select();

    return List<LibraryModel>.from(
        response.map((e) => LibraryModel.fromJson(e)));
  }

  Future<void> addImageToLibrary(int libraryId, int imageId) async {
    final response = await supabase
        .from('library_image')
        .insert({'library_id': libraryId, 'image_id': imageId});

    state = AsyncValue.data(response);
  }
}
