import 'package:picnic_app/services/network_connectivity_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/network_state_provider.g.dart';

@riverpod
class NetworkState extends _$NetworkState {
  @override
  bool build() {
    _initializeNetworkListener();
    return true; // 초기 상태는 true로 설정
  }

  void _initializeNetworkListener() {
    NetworkConnectivityService().connectivityStream.listen((isConnected) {
      state = isConnected;
    });
  }
}
