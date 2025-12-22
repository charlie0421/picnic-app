import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/my_page/vote_artist_list_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

/// 나의 아티스트 검색어 상태 관리 프로바이더
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// 나의 아티스트 페이지
///
/// 공통 [ArtistSelectListView] 위젯을 사용하여 아티스트 목록을 표시하고
/// 북마크 토글 기능을 제공합니다.
class VoteArtistPage extends ConsumerStatefulWidget {
  const VoteArtistPage({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteArtistPage>
    with RouteAwareStateMixin<VoteArtistPage> {
  String? _currentTitle;
  final GlobalKey<_ArtistSelectListViewState> _listViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    logger.i('🎯 VoteArtistPage initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('🎯 VoteArtistPage setting title');
      try {
        _currentTitle = AppLocalizations.of(context).label_mypage_my_artist;
        _updateNavigation();
        logger.i('🎯 VoteArtistPage title set successfully');
      } catch (e) {
        logger.e('🎯 VoteArtistPage title setting failed: $e');
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
    try {
      final provider = ref.read(asyncVoteArtistListProvider.notifier);

      if (artist.isBookmarked == true) {
        // 북마크 해제
        final bookmarkedProvider =
            ref.read(asyncBookmarkedArtistsProvider.notifier);
        final success = await provider.unBookmarkArtist(
          artistId: artist.id,
          bookmarkedArtistsRef: bookmarkedProvider,
        );

        if (success) {
          logger.i('북마크 해제됨: ${getLocaleTextFromJson(artist.name)}');
          // 공통 위젯의 리스트 새로고침
          (_listViewKey.currentState as dynamic)?.refresh();
        }
      } else {
        // 북마크 추가
        final success = await provider.bookmarkArtist(artistId: artist.id);

        if (success) {
          logger.i('북마크 추가됨: ${getLocaleTextFromJson(artist.name)}');
          // 공통 위젯의 리스트 새로고침
          (_listViewKey.currentState as dynamic)?.refresh();
        } else {
          logger.w('북마크 추가 실패 (최대 5개 제한)');
          SnackbarUtil().show(
            AppLocalizations.of(navigatorKey.currentContext!)
                .toast_max_five_celeb,
          );
        }
      }
    } catch (e) {
      logger.e('북마크 토글 실패', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('🎯 VoteArtistPage build called');

    return ArtistSelectListView(
      key: _listViewKey,
      searchQueryProvider: searchQueryProvider,
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

// GlobalKey 사용을 위한 타입 별칭
typedef _ArtistSelectListViewState = ConsumerState<ArtistSelectListView>;
