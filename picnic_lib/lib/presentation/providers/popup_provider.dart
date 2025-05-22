import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/repositories/popup_repository.dart';
import '../../data/models/common/popup.dart';

final popupProvider = FutureProvider<List<Popup>>((ref) async {
  final repo = PopupRepository();
  return repo.fetchPopups();
});
