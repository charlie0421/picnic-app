import 'package:prame_app/mockup/mock_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celeb_search_provider.g.dart';

@riverpod
class CelebSearch extends _$CelebSearch {
  @override
  List<LandingItem> build() {
    return findYourFav;
  }
}
