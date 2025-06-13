import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/home/community_home.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class CommunityHomePage extends ConsumerStatefulWidget {
  const CommunityHomePage({super.key});

  @override
  ConsumerState<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends ConsumerState<CommunityHomePage> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
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
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);
    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));

    return ListView(children: [
      const CommonBanner('community_home', 3144 / 1200),
      const SizedBox(height: 32),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Text('My ARTISTS',
            style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
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
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              height: 84,
                              child: ListView.separated(
                                itemCount: artists.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(communityStateInfoProvider
                                              .notifier)
                                          .setCurrentArtist(artists[index]);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(64),
                                                border: Border.all(
                                                    color: currentArtist?.id ==
                                                            artists[index].id
                                                        ? AppColors.primary500
                                                        : Colors.transparent,
                                                    width: 4),
                                              ),
                                              child: Center(
                                                child: ProfileImageContainer(
                                                  avatarUrl:
                                                      artists[index].image,
                                                  width: 54,
                                                  height: 54,
                                                  borderRadius: 54,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                                getLocaleTextFromJson(
                                                    artists[index].name),
                                                style: getTextStyle(
                                                    AppTypo.caption12R,
                                                    AppColors.grey900)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return SizedBox(width: 14.w);
                                },
                              ),
                            ),
                            if (currentArtist != null) const CommunityHome(),
                          ],
                        )
                      : Container(
                          alignment: Alignment.center,
                          child: Text('No bookmarked artists',
                              style: getTextStyle(
                                  AppTypo.body16R, AppColors.grey500)),
                        );
                },
                loading: () => buildLoadingOverlay(),
                error: (error, stack) => Text('Error: $error'),
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
                alignment: Alignment.center,
                child: Text(t('label_mypage_should_login'),
                    style:
                        getTextStyle(AppTypo.title18B, AppColors.primary500)),
              ),
            ),
    ]);
  }
}
