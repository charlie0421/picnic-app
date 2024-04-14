import 'package:prame_app/models/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_celeb_provider.g.dart';

@riverpod
class SelectedCeleb extends _$SelectedCeleb {
  CelebModel? selectedCeleb; // 초기 값이 필요하다면 임시로 할당

  @override
  CelebModel? build() => selectedCeleb;

  Future<void> setSelectedCeleb(CelebModel? celebModel) {
    state = celebModel;
    return Future.value();
  }
}
