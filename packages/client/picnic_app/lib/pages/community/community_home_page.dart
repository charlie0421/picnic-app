import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/common_banner.dart';
import 'package:picnic_app/components/community/post_list.dart';
import 'package:picnic_app/providers/mypage/bookmarked_artists_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class CommunityHomePage extends ConsumerStatefulWidget {
  const CommunityHomePage({super.key});

  @override
  ConsumerState<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends ConsumerState<CommunityHomePage> {
  int _selectedArtistId = 0;
  @override
  Widget build(BuildContext context) {
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);

    return ListView(children: [
      CommonBanner('community_home', 150),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Text('My ARTISTS',
            style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
      ),
      const SizedBox(height: 16),
      Container(
        child: bookmarkedArtists.when(
          data: (artists) {
            return artists.isNotEmpty
                ? Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        height: 84,
                        child: ListView.separated(
                          itemCount: artists.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedArtistId = artists[index].id;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(64),
                                        border: Border.all(
                                            color: _selectedArtistId ==
                                                    artists[index].id
                                                ? AppColors.primary500
                                                : Colors.transparent,
                                            width: 4),
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
                                        getLocaleTextFromJson(
                                            artists[index].name),
                                        style: getTextStyle(AppTypo.caption12R,
                                            AppColors.grey900)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(width: 14.w);
                          },
                        ),
                      ),
                      PostList(_selectedArtistId),
                    ],
                  )
                : Container(
                    alignment: Alignment.center,
                    child: Text('No bookmarked artists',
                        style:
                            getTextStyle(AppTypo.body16R, AppColors.grey500)),
                  );
          },
          loading: () => buildLoadingOverlay(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    ]);
  }
}
