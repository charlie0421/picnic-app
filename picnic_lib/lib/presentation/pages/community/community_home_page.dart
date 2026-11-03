import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/home/community_home.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_section_header.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';

class CommunityHomePage extends ConsumerStatefulWidget {
  const CommunityHomePage({super.key});

  @override
  ConsumerState<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends ConsumerState<CommunityHomePage>
    with
        SingleTickerProviderStateMixin<CommunityHomePage>,
        RouteAwareStateMixin<CommunityHomePage> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavigation();
      _updateLoginState();
    });

    // Supabase 인증 상태 변경 감지
    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      if (mounted) {
        // 위젯이 아직 마운트된 상태인지 확인
        _updateLoginState();
      }
    });
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _updateLoginState() {
    if (mounted) {
      // ref 사용 전에 위젯이 마운트된 상태인지 확인
      // ignore: unused_result
      ref.refresh(asyncBookmarkedArtistsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 커뮤니티 홈 활성 상태(루트)일 때만 타이틀 비우기
    final navState = ref.watch(navigationInfoProvider);
    final bool isCommunityActive = navState.portalType == PortalType.community;
    final bool isAtRoot =
        navState.voteNavigationStack == null ||
        navState.voteNavigationStack!.length <= 1;
    if (isCommunityActive && isAtRoot && navState.pageTitle.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(navigationInfoProvider.notifier).setPageTitle(pageTitle: '');
        }
      });
    }

    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);
    final currentArtist = ref.watch(
      communityStateInfoProvider.select((value) => value.currentArtist),
    );

    return ListView(
      children: [
        const CommonBanner('community_home', 3144 / 1200),
        const SizedBox(height: 32),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: const PicnicSectionHeader(title: 'My ARTISTS'),
        ),
        const SizedBox(height: 16),
        isSupabaseLoggedSafely
            ? Container(
                child: bookmarkedArtists.when(
                  data: (artists) {
                    if ((currentArtist?.id == null ||
                            !artists.contains(currentArtist)) &&
                        artists.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref
                            .read(communityStateInfoProvider.notifier)
                            .setCurrentArtist(artists[0]);
                      });
                    }
                    return artists.isNotEmpty
                        ? Column(
                            children: [
                              _buildArtistStrip(
                                context,
                                artists,
                                currentArtist,
                              ),
                              if (currentArtist != null) const CommunityHome(),
                            ],
                          )
                        : PicnicFeedback(
                            key: const ValueKey('community-bookmarks-empty'),
                            message: AppLocalizations.of(
                              context,
                            ).label_no_celeb,
                          );
                  },
                  loading: () => buildLoadingOverlay(),
                  error: (error, stack) => PicnicFeedback(
                    key: const ValueKey('community-bookmarks-retry'),
                    message: AppLocalizations.of(
                      context,
                    ).message_error_occurred,
                    actionLabel: AppLocalizations.of(context).label_retry,
                    onAction: () =>
                        ref.invalidate(asyncBookmarkedArtistsProvider),
                  ),
                ),
              )
            : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ).then((_) {
                    _updateLoginState();
                  });
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: EdgeInsets.symmetric(
                    horizontal: PicnicUi.horizontal(16),
                    vertical: PicnicUi.vertical(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context).label_mypage_should_login,
                    style: PicnicUi.text(
                      size: 16,
                      weight: FontWeight.w600,
                      color: PicnicUi.actionColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildArtistStrip(
    BuildContext context,
    List<ArtistModel> artists,
    ArtistModel? currentArtist,
  ) {
    const itemWidth = 88.0;
    final nameStyle = PicnicUi.text(size: 12);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final labels = [
      for (final artist in artists) getLocaleTextFromJson(artist.name, context),
    ];
    var nameHeight = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: nameStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: itemWidth);
      if (painter.height > nameHeight) nameHeight = painter.height;
      painter.dispose();
    }
    // Keep the image viewport lazy. Only text metrics are measured for the full
    // list, so large text can grow the strip without fetching offscreen avatars.
    return SizedBox(
      height: 64 + 2 + nameHeight,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, _) => SizedBox(width: 14.w),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => ref
              .read(communityStateInfoProvider.notifier)
              .setCurrentArtist(artists[index]),
          child: SizedBox(
            width: itemWidth,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64),
                    border: Border.all(
                      color: currentArtist?.id == artists[index].id
                          ? AppColors.primary500
                          : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: ProfileImageContainer(
                      avatarUrl: artists[index].image,
                      width: 54,
                      height: 54,
                      borderRadius: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labels[index],
                  style: nameStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: true,
            topRightMenu: TopRightType.community,
            pageTitle: '',
          );
    });
  }
}
