import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/common_banner.dart';
import 'package:picnic_app/components/community/home/post_home_list.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/mypage/bookmarked_artists_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class CommunityHomePage extends ConsumerStatefulWidget {
  const CommunityHomePage({super.key});

  @override
  ConsumerState<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends ConsumerState<CommunityHomePage> {
  int? _selectedArtistId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: true, showBottomNavigation: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkedArtists = ref.watch(asyncBookmarkedArtistsProvider);

    return ListView(children: [
      const CommonBanner('community_home', 150),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Text('My ARTISTS',
            style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
      ),
      const SizedBox(height: 16),
      Container(
        child: bookmarkedArtists.when(
          data: (artists) {
            if (_selectedArtistId == null && artists.isNotEmpty) {
              _selectedArtistId = artists.first.id;
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
                                          borderRadius:
                                              BorderRadius.circular(64),
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
                                          style: getTextStyle(
                                              AppTypo.caption12R,
                                              AppColors.grey900)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(width: 14.w);
                          },
                        ),
                      ),
                      if (_selectedArtistId != null)
                        BoardContent(artistId: _selectedArtistId!),
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

class BoardContent extends ConsumerWidget {
  final int artistId;

  const BoardContent({Key? key, required this.artistId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider(artistId));

    return boardState.when(
      data: (board) => PostHomeList(board.board_id),
      loading: () => buildLoadingOverlay(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

final boardProvider = FutureProvider.family((ref, int artistId) async {
  try {
    final response = await supabase
        .schema('community')
        .from('boards')
        .select('* ')
        .eq('artist_id', artistId)
        .maybeSingle();
    logger.d('response: $response');
    return BoardModel.fromJson(response!);
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
});
