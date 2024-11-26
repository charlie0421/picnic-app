import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/community/list/post_list.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/pages/community/board_request.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class PostListPage extends ConsumerStatefulWidget {
  const PostListPage(this.artistId, this.artistName, {super.key});

  final int artistId;
  final String artistName;

  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final PageController _pageController = PageController();
  late final BoardsNotifier _boardsNotifier;
  int _currentIndex = 0;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _boardsNotifier =
        ref.read(boardsNotifierProvider(widget.artistId).notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: widget.artistName);
    });
  }

  void _initializeWithCurrentBoard(List<BoardModel> boards) {
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
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(newIndex);
          }
        });
      }
    } else {
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ref.watch(boardsNotifierProvider(widget.artistId)).when(
          data: (boards) {
            if (boards == null || boards.isEmpty) {
              return const Center(child: Text('No boards available'));
            }

            if (!_isInitialized) {
              _initializeWithCurrentBoard(boards);
            }

            final currentUser = supabase.auth.currentUser;
            final bool hasApprovedBoards = currentUser != null &&
                boards.any((board) =>
                    board.status == 'approved' &&
                    board.creatorId == currentUser.id);

            final bool hasPendingBoard = currentUser != null &&
                boards.any((board) =>
                    board.status == 'pending' &&
                    board.creatorId == currentUser.id);

            final bool showRequestButton =
                !hasApprovedBoards || hasPendingBoard;
            final int totalPages =
                showRequestButton ? boards.length + 2 : boards.length + 1;

            return Column(
              children: [
                _buildTabBar(boards, totalPages, showRequestButton),
                Expanded(child: _buildPageView(boards, showRequestButton)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            logger.e('Error fetching boards:',
                error: error, stackTrace: stackTrace);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context).message_error_occurred),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _boardsNotifier.refresh(),
                    child: Text(S.of(context).label_retry),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildTabBar(
      List<BoardModel> boards, int totalPages, bool showRequestButton) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey300, width: 1)),
      ),
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMenuItem(S.of(context).common_all, index);
          } else if (index <= boards.length) {
            return _buildMenuItem(
                getLocaleTextFromJson(boards[index - 1].name), index);
          } else {
            return _buildOpenRequestItem(totalPages - 1);
          }
        },
      ),
    );
  }

  Widget _buildPageView(List<BoardModel> boards, bool showRequestButton) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        if (index != 0 && index <= boards.length) {
          ref
              .read(communityStateInfoProvider.notifier)
              .setCurrentBoard(boards[index - 1]);
        } else {
          ref.read(communityStateInfoProvider.notifier).setCurrentBoard(null);
        }
      },
      children: [
        PostList(PostListType.artist, widget.artistId),
        ...boards.map((board) => PostList(PostListType.board, board.boardId)),
        if (showRequestButton) BoardRequest(widget.artistId),
      ],
    );
  }

  Widget _buildMenuItem(String title, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() => _currentIndex = index);
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
                        strokeAlign: BorderSide.strokeAlignInside)),
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
        if (!supabase.isLogged) {
          showRequireLoginDialog();
          return;
        }
        _pageController.jumpToPage(index);
        setState(() => _currentIndex = index);
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
                        strokeAlign: BorderSide.strokeAlignInside)),
              )
            : null,
        child: Row(
          children: [
            Text(S.of(context).post_board_request_label,
                style: getTextStyle(AppTypo.caption12B, AppColors.grey700)),
            const SizedBox(width: 4),
            SvgPicture.asset(
              'assets/icons/plus_style=fill.svg',
              width: 16,
              height: 16,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey700, BlendMode.srcIn),
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
