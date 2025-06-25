import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

class PostBoardSelectPopupMenu extends ConsumerStatefulWidget {
  final int artistId;
  final Function refreshFunction;
  final Function? openReportModal;

  const PostBoardSelectPopupMenu({
    super.key,
    required this.artistId,
    required this.refreshFunction,
    this.openReportModal,
  });

  @override
  ConsumerState<PostBoardSelectPopupMenu> createState() =>
      _PostBoardSelectPopupMenuState();
}

class _PostBoardSelectPopupMenuState
    extends ConsumerState<PostBoardSelectPopupMenu> {
  @override
  Widget build(BuildContext context) {
    final currentBoard = ref.watch(communityStateInfoProvider.select(
      (value) => value.currentBoard,
    ));

    return ref.watch(boardsNotifierProvider(widget.artistId)).when(
          data: (boards) {
            if (boards == null || boards.isEmpty) {
              return const SizedBox.shrink();
            }

            final selectedBoard = boards.firstWhere(
              (board) => board.boardId == currentBoard?.boardId,
              orElse: () => boards.first,
            );

            // 초기 보드 설정
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(communityStateInfoProvider.notifier)
                  .setCurrentBoard(selectedBoard);
            });

            return PopupMenuButton<BoardModel>(
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              child: _buildSelectedBoardButton(selectedBoard),
              itemBuilder: (context) => _buildMenuItems(boards, currentBoard),
              onSelected: (BoardModel board) {
                ref
                    .read(communityStateInfoProvider.notifier)
                    .setCurrentBoard(board);
                logger.i('Selected board: ${board.boardId}');
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: MediumPulseLoadingIndicator(),
          ),
          error: (error, stackTrace) {
            logger.e('Error loading boards:',
                error: error, stackTrace: stackTrace);
            return const SizedBox.shrink();
          },
        );
  }

  Widget _buildSelectedBoardButton(BoardModel selectedBoard) {
    return Container(
      height: 26,
      width: 120.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300, width: 1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              getLocaleTextFromJson(selectedBoard.name),
              textAlign: TextAlign.center,
              style: getTextStyle(AppTypo.caption12R, AppColors.grey700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: AppColors.grey700,
          ),
        ],
      ),
    );
  }

  List<PopupMenuItem<BoardModel>> _buildMenuItems(
      List<BoardModel> boards, BoardModel? currentBoard) {
    return boards.map((BoardModel board) {
      final isSelected = board.boardId == currentBoard?.boardId;
      return PopupMenuItem<BoardModel>(
        value: board,
        height: 36,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            getLocaleTextFromJson(board.name),
            style: getTextStyle(
              isSelected ? AppTypo.caption12B : AppTypo.caption12R,
              isSelected ? AppColors.grey700 : AppColors.grey400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }
}
