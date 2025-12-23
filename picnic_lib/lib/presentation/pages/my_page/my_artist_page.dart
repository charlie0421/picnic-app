import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/my_page/my_artist_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

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

  Future<void> _toggleBookmark(ArtistModel artist) async {
    if (!mounted) return;

    try {
      final provider = ref.read(asyncMyArtistProvider.notifier);
      final l10n = AppLocalizations.of(context);

      if (artist.isBookmarked == true) {
        // 북마크 해제
        final success = await provider.unBookmarkArtist(artistId: artist.id);

        if (!mounted) return;

        if (success) {
          logger.i('북마크 해제됨: ${getLocaleTextFromJson(artist.name)}');
          // 즉시 UI 업데이트
          _listViewKey.currentState?.updateBookmarkState(artist.id, false);
          SnackbarUtil().show(l10n.toast_bookmark_removed, context: context);
        }
      } else {
        // 북마크 추가
        final success = await provider.bookmarkArtist(artistId: artist.id);

        if (!mounted) return;

        if (success) {
          logger.i('북마크 추가됨: ${getLocaleTextFromJson(artist.name)}');
          // 즉시 UI 업데이트
          _listViewKey.currentState?.updateBookmarkState(artist.id, true);
          SnackbarUtil().show(l10n.toast_bookmark_added, context: context);
        } else {
          logger.w('북마크 추가 실패 (최대 5개 제한)');
          SnackbarUtil().show(l10n.toast_max_five_celeb, context: context);
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
