// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/my_page/bookmark_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 북마크 상태를 전역으로 관리하는 Provider
///
/// 로컬 UI 업데이트와 서버 동기화를 분리하여 빠른 반응성을 제공합니다.
/// - 즉시 UI 반영: updateBookmarkState() 호출 시 바로 상태 변경
/// - 서버 동기화: asyncBookmarkedArtistsProvider에서 별도 처리

@ProviderFor(BookmarkState)
const bookmarkStateProvider = BookmarkStateProvider._();

/// 북마크 상태를 전역으로 관리하는 Provider
///
/// 로컬 UI 업데이트와 서버 동기화를 분리하여 빠른 반응성을 제공합니다.
/// - 즉시 UI 반영: updateBookmarkState() 호출 시 바로 상태 변경
/// - 서버 동기화: asyncBookmarkedArtistsProvider에서 별도 처리
final class BookmarkStateProvider
    extends $NotifierProvider<BookmarkState, Map<int, bool>> {
  /// 북마크 상태를 전역으로 관리하는 Provider
  ///
  /// 로컬 UI 업데이트와 서버 동기화를 분리하여 빠른 반응성을 제공합니다.
  /// - 즉시 UI 반영: updateBookmarkState() 호출 시 바로 상태 변경
  /// - 서버 동기화: asyncBookmarkedArtistsProvider에서 별도 처리
  const BookmarkStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkStateHash();

  @$internal
  @override
  BookmarkState create() => BookmarkState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, bool>>(value),
    );
  }
}

String _$bookmarkStateHash() => r'cf76785fcc0468d52b63f7303d6358794dc38b35';

/// 북마크 상태를 전역으로 관리하는 Provider
///
/// 로컬 UI 업데이트와 서버 동기화를 분리하여 빠른 반응성을 제공합니다.
/// - 즉시 UI 반영: updateBookmarkState() 호출 시 바로 상태 변경
/// - 서버 동기화: asyncBookmarkedArtistsProvider에서 별도 처리

abstract class _$BookmarkState extends $Notifier<Map<int, bool>> {
  Map<int, bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<int, bool>, Map<int, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<int, bool>, Map<int, bool>>,
              Map<int, bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
