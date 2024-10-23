import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/community/list/post_list.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/pages/community/board_request.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  void _initializeWithCurrentBoard(List<dynamic> boards) {
    if (_isInitialized) return;

    final currentBoard = ref.read(communityStateInfoProvider).currentBoard;
    if (currentBoard != null) {
      final index =
          boards.indexWhere((board) => board.boardId == currentBoard.boardId);
      if (index != -1) {
        final newIndex = index + 1;
        setState(() {
          _currentIndex = newIndex;
          _isInitialized = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.jumpToPage(newIndex);
          }
        });
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final boards = ref.watch(boardsProvider(widget.artistId));

    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: widget.artistName);
      });
    }

    return boards.when(
        data: (data) {
          if (data != null && data.isNotEmpty) {
            if (!_isInitialized) {
              _initializeWithCurrentBoard(data);
            }

            final bool hasApprovedBoards = data.any((element) =>
                element.status == 'approved' &&
                element.creatorId == supabase.auth.currentUser!.id);

            final bool hasPendingBoard = data.any((element) =>
                element.status == 'pending' &&
                element.creatorId == supabase.auth.currentUser!.id);

            final bool showRequestButton =
                !hasApprovedBoards || hasPendingBoard;

            final int totalPages =
                showRequestButton ? data.length + 2 : data.length + 1;

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
                        return _buildMenuItem('전체', index);
                      } else if (index <= data.length) {
                        final board = data[index - 1];
                        return _buildMenuItem(
                            getLocaleTextFromJson(board.name), index);
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
                      logger.i('onPageChanged: $index');
                      setState(() {
                        _currentIndex = index;
                      });
                      if (index != 0 && index <= data.length) {
                        ref
                            .read(communityStateInfoProvider.notifier)
                            .setCurrentBoard(data[index - 1]);
                      } else {
                        ref
                            .read(communityStateInfoProvider.notifier)
                            .setCurrentBoard(null);
                      }
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
