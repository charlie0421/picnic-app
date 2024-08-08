import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/common_banner.dart';
import 'package:picnic_app/providers/mypage/bookmarked_artists_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class CommunityHomePage extends ConsumerWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);

    return ListView(children: [
      const CommonBanner('community_home'),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Text('My ARTISTS',
            style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900)),
      ),
      SizedBox(height: 16.h),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        height: 90,
        child: bookmarkedArtists.when(
          data: (artists) {
            return artists.isNotEmpty
                ? ListView.separated(
                    itemCount: artists.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            ProfileImageContainer(
                              avatarUrl: artists[index].image,
                              width: 54,
                              height: 54,
                              borderRadius: 54,
                            ),
                            const SizedBox(height: 7),
                            Text(getLocaleTextFromJson(artists[index].name),
                                style: getTextStyle(
                                    AppTypo.CAPTION12R, AppColors.Grey900)),
                          ],
                        ),
                      ],
                    ),
                    separatorBuilder: (BuildContext context, int index) {
                      return SizedBox(width: 14.w);
                    },
                  )
                : Container();
          },
          loading: () => buildLoadingOverlay(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    ]);
  }
}
