import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/board_request.dart';
import 'package:picnic_lib/presentation/providers/artist_provider.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/list/post_list.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

class BoardHomePage extends ConsumerStatefulWidget {
  const BoardHomePage(this.artistId, {super.key});

  final int artistId;

  @override
  ConsumerState<BoardHomePage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<BoardHomePage>
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final artist = await ref.read(getArtistProvider(widget.artistId).future);
      if (!mounted) return;

      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: getLocaleTextFromJson(artist.name));
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
                Expanded(
                    child: _buildPageView(
                        boards, widget.artistId, showRequestButton)),
              ],
            );
          },
          loading: () => const Center(child: MediumPulseLoadingIndicator()),
          error: (error, stackTrace) {
            logger.e('Error fetching boards:',
                error: error, stackTrace: stackTrace);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('message_error_occurred')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _boardsNotifier.refresh(),
                    child: Text(t('label_retry')),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey300, width: 1)),
      ),
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMenuItem(t('common_all'), index);
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

  Widget _buildPageView(
      List<BoardModel> boards, int artistId, bool showRequestButton) {
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
        PostList(PostListType.artist, artistId),
        ...boards.map((board) => PostList(PostListType.board, board.boardId)),
        if (showRequestButton) BoardRequest(artistId),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        height: 32,
        constraints: BoxConstraints(minWidth: 80.w),
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
        if (!isSupabaseLoggedSafely) {
          showRequireLoginDialog();
          return;
        }
        _pageController.jumpToPage(index);
        setState(() => _currentIndex = index);
      },
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minWidth: 80.w),
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
            Text(t('post_board_request_label'),
                style: getTextStyle(AppTypo.caption12B, AppColors.grey700)),
            const SizedBox(width: 4),
            SvgPicture.asset(
              package: 'picnic_lib',
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
