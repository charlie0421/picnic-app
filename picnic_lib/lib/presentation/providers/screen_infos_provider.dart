import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/screen_infos_provider.g.dart';

@Riverpod(keepAlive: true)
class ScreenInfos extends AsyncNotifier<Map<String, ScreenInfo>> {
  @override
  FutureOr<Map<String, ScreenInfo>> build() async {
    return Future.value({});
  }

  void setScreenInfoMap(Map<String, ScreenInfo> newScreenInfoMap) {
    state = AsyncLoading();
    state = AsyncData(newScreenInfoMap);
  }
}
