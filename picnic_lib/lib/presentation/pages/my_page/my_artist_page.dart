import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmark_state_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/my_artist_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/ui/style.dart';

/// 나의 아티스트 검색어 상태 관리 프로바이더
class MyArtistSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final myArtistSearchQueryProvider =
    NotifierProvider<MyArtistSearchQueryNotifier, String>(
  MyArtistSearchQueryNotifier.new,
);

/// 나의 아티스트 페이지
///
/// 공통 [ArtistSelectListView] 위젯을 사용하여 아티스트 목록을 표시하고
/// 북마크 토글 기능을 제공합니다.
class MyArtistPage extends ConsumerStatefulWidget {
  const MyArtistPage({super.key});

  @override
  ConsumerState createState() => _MyArtistPageState();
}

class _MyArtistPageState extends ConsumerState<MyArtistPage>
    with RouteAwareStateMixin<MyArtistPage> {
  String? _currentTitle;
  final GlobalKey<ArtistSelectListViewState> _listViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    logger.i('🎯 MyArtistPage initState called');

    // 페이지 진입 시 검색어 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(myArtistSearchQueryProvider.notifier).set('');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('🎯 MyArtistPage setting title');
      try {
        _currentTitle = AppLocalizations.of(context).label_mypage_my_artist;
        _updateNavigation();
        logger.i('🎯 MyArtistPage title set successfully');
      } catch (e) {
        logger.e('🎯 MyArtistPage title setting failed: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).label_mypage_my_artist;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
            pageTitle: title,
          );
    });
  }

  /// 토스트 메시지 표시 (overlay_support 사용)
  void _showToast(String message) {
    if (!mounted) return;
    // overlay_support의 showSimpleNotification 사용 - 전역적으로 동작
    showSimpleNotification(
      Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      background: AppColors.point500,
      duration: const Duration(seconds: 2),
      slideDismissDirection: DismissDirection.up,
    );
    logger.i('🔔 토스트 표시됨: $message');
  }

  /// MyPage의 북마크 아티스트 리스트 새로고침
  void _refreshBookmarkedArtists() {
    if (!mounted) return;
    // asyncBookmarkedArtistsProvider를 새로고침하여 MyPage에 반영
    ref.read(asyncBookmarkedArtistsProvider.notifier).refreshBookmarkedArtists();
    logger.i('🔖 북마크 아티스트 리스트 새로고침 요청');
  }

  /// 북마크 상태 업데이트 (UI만 변경, 위치 이동 없음)
  void _updateBookmarkUI(int artistId, bool isBookmarked) {
    if (!mounted) return;
    // UI 상태만 변경 (별 아이콘, 배경색)
    _listViewKey.currentState?.updateBookmarkState(artistId, isBookmarked);
    // 캐시 무효화 (다음 페이지 진입 시 서버 데이터 반영)
    SearchService.invalidateCache('artist_fast');
    logger.i('🔄 북마크 UI 업데이트 - artistId: $artistId, isBookmarked: $isBookmarked');
  }

  Future<void> _toggleBookmark(ArtistModel artist) async {
    if (!mounted) return;

    try {
      final provider = ref.read(asyncMyArtistProvider.notifier);
      final bookmarkProvider = ref.read(bookmarkStateProvider.notifier);
      final l10n = AppLocalizations.of(context);

      if (artist.isBookmarked == true) {
        // 북마크 해제 - 먼저 UI 업데이트 (낙관적 업데이트)
        bookmarkProvider.updateBookmarkState(artist.id, false);

        final success = await provider.unBookmarkArtist(artistId: artist.id);

        if (!mounted) return;

        if (success) {
          logger.i('북마크 해제됨: ${getLocaleTextFromJson(artist.name)}');
          _showToast(l10n.toast_bookmark_removed);
          // UI 업데이트 및 캐시 무효화
          _updateBookmarkUI(artist.id, false);
          // MyPage의 북마크 리스트도 새로고침
          _refreshBookmarkedArtists();
        } else {
          // 실패 시 롤백
          bookmarkProvider.updateBookmarkState(artist.id, true);
        }
      } else {
        // 북마크 추가 - 먼저 UI 업데이트 (낙관적 업데이트)
        bookmarkProvider.updateBookmarkState(artist.id, true);

        final success = await provider.bookmarkArtist(artistId: artist.id);

        if (!mounted) return;

        if (success) {
          logger.i('북마크 추가됨: ${getLocaleTextFromJson(artist.name)}');
          _showToast(l10n.toast_bookmark_added);
          // UI 업데이트 및 캐시 무효화
          _updateBookmarkUI(artist.id, true);
          // MyPage의 북마크 리스트도 새로고침
          _refreshBookmarkedArtists();
        } else {
          // 실패 시 롤백
          bookmarkProvider.updateBookmarkState(artist.id, false);
          logger.w('북마크 추가 실패 (최대 5개 제한)');
          _showToast(l10n.toast_max_five_celeb);
        }
      }
    } catch (e) {
      logger.e('북마크 토글 실패', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('🎯 MyArtistPage build called');

    return ArtistSelectListView(
      key: _listViewKey,
      searchQueryProvider: myArtistSearchQueryProvider,
      config: const ArtistSelectConfig(
        showBookmarkToggle: true,
        hideSectionHeaderOnSearch: false,
        bookmarkSectionTitle: '북마크',
        generalSectionTitle: '전체 아티스트',
      ),
      onBookmarkToggle: _toggleBookmark,
      onArtistTap: (artist) {
        logger.i(
            'Artist tapped: ${getLocaleTextFromJson(artist.name)} - 북마크 상태: ${artist.isBookmarked}');
      },
    );
  }
}
