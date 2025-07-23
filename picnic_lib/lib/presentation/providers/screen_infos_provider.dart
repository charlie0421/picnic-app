import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';

final screenInfosProvider = StateProvider<Map<String, ScreenInfo>>((ref) {
  return {};
});
