import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/my_page/bookmark_state_provider.g.dart';

/// 북마크 상태를 전역으로 관리하는 Provider
///
/// 로컬 UI 업데이트와 서버 동기화를 분리하여 빠른 반응성을 제공합니다.
/// - 즉시 UI 반영: updateBookmarkState() 호출 시 바로 상태 변경
/// - 서버 동기화: asyncBookmarkedArtistsProvider에서 별도 처리
@Riverpod(keepAlive: true)
class BookmarkState extends _$BookmarkState {
  @override
  Map<int, bool> build() {
    return {};
  }

  /// 특정 아티스트의 북마크 상태를 업데이트합니다.
  void updateBookmarkState(int artistId, bool isBookmarked) {
    state = {...state, artistId: isBookmarked};
  }

  /// 특정 아티스트의 북마크 상태를 반환합니다.
  /// 오버라이드가 없으면 null 반환 (원본 데이터 사용)
  bool? getBookmarkState(int artistId) {
    return state[artistId];
  }

  /// 북마크 상태 오버라이드를 초기화합니다.
  /// 서버에서 새로운 데이터를 받아올 때 호출
  void clearOverrides() {
    state = {};
  }

  /// 특정 아티스트의 오버라이드를 제거합니다.
  void removeOverride(int artistId) {
    final newState = Map<int, bool>.from(state);
    newState.remove(artistId);
    state = newState;
  }
}
