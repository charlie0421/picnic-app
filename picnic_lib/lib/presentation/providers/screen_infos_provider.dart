import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/screen_infos_provider.g.dart';

@Riverpod(keepAlive: true)
class ScreenInfos extends _$ScreenInfos {
  Map<String, ScreenInfo> _screenInfoMap = {};

  @override
  FutureOr<Map<String, ScreenInfo>> build() async {
    return _screenInfoMap;
  }

  void setScreenInfoMap(Map<String, ScreenInfo> newScreenInfoMap) {
    _screenInfoMap = newScreenInfoMap;
    state = AsyncData(_screenInfoMap);
  }
}
