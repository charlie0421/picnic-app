import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';

class ScreenInfosNotifier extends Notifier<Map<String, ScreenInfo>> {
  @override
  Map<String, ScreenInfo> build() => {};

  void update(Map<String, ScreenInfo> value) {
    state = value;
  }

  void add(String key, ScreenInfo info) {
    state = {...state, key: info};
  }

  void remove(String key) {
    final newState = Map<String, ScreenInfo>.from(state);
    newState.remove(key);
    state = newState;
  }
}

final screenInfosProvider =
    NotifierProvider<ScreenInfosNotifier, Map<String, ScreenInfo>>(
  ScreenInfosNotifier.new,
);
