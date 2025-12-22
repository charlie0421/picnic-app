import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_input_page.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/ui/style.dart';

/// 궁합 아티스트 검색어 상태 관리 프로바이더
class GoonghapArtistSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final goonghapArtistSearchQueryProvider =
    NotifierProvider<GoonghapArtistSearchQueryNotifier, String>(
  GoonghapArtistSearchQueryNotifier.new,
);

/// 궁합 아티스트 선택 페이지
///
/// 공통 [ArtistSelectListView] 위젯을 사용하여 아티스트 목록을 표시하고
/// 아티스트 선택 시 [GoonghapInputPage]로 이동합니다.
class GoonghapArtistSelectPage extends ConsumerStatefulWidget {
  const GoonghapArtistSelectPage({super.key});

  @override
  ConsumerState<GoonghapArtistSelectPage> createState() =>
      _GoonghapArtistSelectPageState();
}

class _GoonghapArtistSelectPageState
    extends ConsumerState<GoonghapArtistSelectPage>
    with RouteAwareStateMixin<GoonghapArtistSelectPage> {
  @override
  void initState() {
    super.initState();
    _updateNavigation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showMyPoint: false,
            topRightMenu: TopRightType.none,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).goonghap_new,
          );
    });
  }

  void _onArtistTap(ArtistModel artist) {
    logger.i('Artist selected: ${getLocaleTextFromJson(artist.name)}');

    // 생년월일이 없는 아티스트는 궁합 계산 불가
    if (artist.birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).goonghap_artist_no_birthdate,
          ),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
          GoonghapInputPage(artist: artist),
        );
  }

  @override
  Widget build(BuildContext context) {
    // 스택의 최상단 페이지가 현재 페이지일 때 네비게이션 복구
    ref.listen(
      navigationInfoProvider.select((s) => s.voteNavigationStack?.peek()),
      (previous, next) {
        if (next is GoonghapArtistSelectPage) {
          _updateNavigation();
        }
      },
    );

    return ArtistSelectListView(
      searchQueryProvider: goonghapArtistSearchQueryProvider,
      config: const ArtistSelectConfig(
        showBookmarkToggle: false,
        hideSectionHeaderOnSearch: true,
        bookmarkSectionTitle: '나의 아티스트',
        generalSectionTitle: '전체 아티스트',
      ),
      onArtistTap: _onArtistTap,
    );
  }
}
