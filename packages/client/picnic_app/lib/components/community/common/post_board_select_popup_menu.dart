import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

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
    final currentBoard = ref.watch(
        communityStateInfoProvider.select((value) => value.currentBoard));
    final communityStateNotifier =
        ref.read(communityStateInfoProvider.notifier);

    return FutureBuilder<List<BoardModel>?>(
      future: boards(ref, widget.artistId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final boards = snapshot.data as List<BoardModel>;
          final selectedBoard = boards.firstWhere(
            (board) => board.boardId == currentBoard?.boardId,
            orElse: () => boards.first,
          );

          return PopupMenuButton<BoardModel>(
            padding: EdgeInsets.zero,
            child: Container(
              height: 26,
              width: 120.cw,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 10.cw),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey300, width: 1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                        getLocaleTextFromJson(selectedBoard.name),
                    textAlign: TextAlign.center,
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey700),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      size: 20, color: AppColors.grey700),
                ],
              ),
            ),
            onSelected: (BoardModel board) async {
              communityStateNotifier.setCurrentBoard(board);
              logger.i('board: $board');
            },
            itemBuilder: (BuildContext context) =>
                boards.map((BoardModel board) {
              return PopupMenuItem<BoardModel>(
                value: board,
                child: Text(
                   getLocaleTextFromJson(board.name)
                  ,
                  style: board.boardId == currentBoard?.boardId
                      ? getTextStyle(AppTypo.caption12R, AppColors.grey700)
                      : getTextStyle(AppTypo.caption12B, AppColors.grey400),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
