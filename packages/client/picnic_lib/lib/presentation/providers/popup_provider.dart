import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/common/popup.dart';

final popupProvider = FutureProvider<List<Popup>>((ref) async {
  final repo = PopupRepository();
  return repo.fetchPopups();
});
