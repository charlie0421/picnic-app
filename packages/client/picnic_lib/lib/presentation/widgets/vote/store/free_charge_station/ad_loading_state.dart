import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 통합 광고 로딩 상태 관리
final adLoadingStateProvider =
    StateNotifierProvider<AdLoadingStateNotifier, Map<String, bool>>((ref) {
  return AdLoadingStateNotifier();
});

class AdLoadingStateNotifier extends StateNotifier<Map<String, bool>> {
  AdLoadingStateNotifier() : super({});

  void setLoading(String adId, bool isLoading) {
    state = {...state, adId: isLoading};
  }

  bool isLoading(String adId) {
    return state[adId] ?? false;
  }
}
