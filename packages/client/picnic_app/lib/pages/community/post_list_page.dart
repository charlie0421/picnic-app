import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/community/list/post_list.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/pages/community/board_reqeust.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class PostListPage extends ConsumerStatefulWidget {
  const PostListPage(this.artistId, this.artistName, {super.key});
  final int artistId;
  final String artistName;

  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: widget.artistName);
    });

    _pageController = PageController(
      initialPage: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boards = ref.watch(boardsProvider(widget.artistId));

    return boards.when(
      data: (data) {
        if (data != null && data.isNotEmpty) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.cw),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.grey300,
                      width: 1,
                    ),
                  ),
                ),
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length + 2, // 전체, 각 보드, 오픈요청
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMenuItem('전체', index);
                    } else if (index <= data.length) {
                      return _buildMenuItem(
                          data[index - 1].is_official
                              ? 'Picnic!${getLocaleTextFromJson(data[index - 1].name)}'
                              : data[index - 1].name['minor'],
                          index);
                    } else {
                      return _buildOpenRequestItem(data.length + 1);
                    }
                  },
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    PostList(PostListType.artist, widget.artistId),
                    ...List.generate(data.length, (index) {
                      return PostList(PostListType.board, data[index].board_id);
                    }),
                    BoardRequest(widget.artistId), // 오픈요청 페이지
                  ],
                ),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
      error: (err, stack) => ErrorWidget(err),
      loading: () => buildLoadingOverlay(),
    );
  }

  Widget _buildMenuItem(String title, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        height: 32,
        constraints: BoxConstraints(minWidth: 80.cw),
        decoration: _currentIndex == index
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.black,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignInside),
                ),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          title,
          style: _currentIndex == index
              ? getTextStyle(AppTypo.body14B, AppColors.grey900)
              : getTextStyle(AppTypo.body14R, AppColors.grey600),
        ),
      ),
    );
  }

  Widget _buildOpenRequestItem(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: 80.cw),
        decoration: _currentIndex == index
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.black,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignInside),
                ),
              )
            : null,
        child: Row(
          children: [
            Text(
              '오픈요청',
              style: getTextStyle(AppTypo.caption12B, AppColors.grey700),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              'assets/icons/plus_style=fill.svg',
              width: 16,
              height: 16,
              color: AppColors.grey700,
            ),
          ],
        ),
      ),
    );
  }
}
