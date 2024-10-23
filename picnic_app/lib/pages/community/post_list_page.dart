import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/community/list/post_list.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/pages/community/board_reqeust.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
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
            // 현재 승인된 보드가 있는지 확인
            final bool hasApprovedBoards = data.any((element) =>
                element.status == 'approved' &&
                element.creatorId == supabase.auth.currentUser!.id);

            // 현재 보드에 대해 pending 상태인지 확인
            final bool hasPendingBoard = data.any((element) =>
                element.status == 'pending' &&
                element.creatorId == supabase.auth.currentUser!.id);

            // 새로운 요청 버튼을 보여줄지 결정
            // 1. 승인된 보드가 없고
            // 2. 승인/거절/삭제 이력이 없거나 현재 pending 상태일 때 보여줌
            final bool showRequestButton =
                !hasApprovedBoards || hasPendingBoard;

            logger.i('showRequestButton: $showRequestButton');
            logger.i('hasApprovedBoards: $hasApprovedBoards');
            logger.i('hasPendingBoard: $hasPendingBoard');

            final int totalPages = showRequestButton
                ? data.length + 2 // +2 for '전체' and request page
                : data.length + 1; // +1 for '전체' only

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
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildMenuItem('전체', '', index);
                      } else if (index <= data.length) {
                        final board = data[index - 1];
                        return _buildMenuItem(
                            board.isOfficial
                                ? getLocaleTextFromJson(board.name)
                                : board.name['minor'],
                            board.boardId,
                            index);
                      } else if (showRequestButton) {
                        return _buildOpenRequestItem(totalPages - 1);
                      }
                      return const SizedBox.shrink();
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
                        return PostList(
                            PostListType.board, data[index].boardId);
                      }),
                      if (showRequestButton) BoardRequest(widget.artistId),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          logger.e('Error fetching boards:',
              error: error, stackTrace: stackTrace);
          return const Center(child: Text('Error fetching boards'));
        });
  }

  Widget _buildMenuItem(String title, String boardId, int index) {
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
              colorFilter: const ColorFilter.mode(
                AppColors.grey700,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
