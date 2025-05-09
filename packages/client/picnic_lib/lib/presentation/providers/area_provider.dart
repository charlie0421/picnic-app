import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class AreaNotifier extends StateNotifier<String> {
  AreaNotifier() : super('kpop');

  void setArea(String area) {
    state = area;
    logger.i('area set to: $area');
  }
}

final areaProvider = StateNotifierProvider<AreaNotifier, String>((ref) {
  return AreaNotifier();
});
