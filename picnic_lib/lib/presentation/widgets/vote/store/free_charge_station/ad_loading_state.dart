import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 통합 광고 로딩 상태 관리
final adLoadingStateProvider =
    NotifierProvider<AdLoadingStateNotifier, Map<String, bool>>(
  AdLoadingStateNotifier.new,
);

class AdLoadingStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setLoading(String adId, bool isLoading) {
    state = {...state, adId: isLoading};
  }

  bool isAdLoading(String adId) {
    return state[adId] ?? false;
  }
}
