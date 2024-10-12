import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

import '../../../generated/l10n.dart';
import '../common/post_board_select_popup_menu.dart';

class PostWriteHeader extends ConsumerStatefulWidget {
  final Function onSave;

  const PostWriteHeader({
    super.key,
    required this.onSave,
  });

  @override
  ConsumerState<PostWriteHeader> createState() => _PostWriteHeaderState();
}

class _PostWriteHeaderState extends ConsumerState<PostWriteHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: S.of(context).page_title_post_write,
          topRightMenu: TopRightType.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));
    final currentBoard = ref.watch(
        communityStateInfoProvider.select((value) => value.currentBoard));
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            child: FutureBuilder(
                future: boards(ref, currentArtist!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    BoardModel? initItem;
                    if (currentBoard != null) {
                      initItem = snapshot.data?.firstWhere(
                          (element) =>
                              element.board_id == currentBoard.board_id,
                          orElse: () => snapshot.data!.first);
                    } else {
                      initItem = snapshot.data?.first;
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(communityStateInfoProvider.notifier)
                          .setCurrentBoard(initItem!);
                    });
                    return Container(
                      constraints:
                          const BoxConstraints(minWidth: 100, maxWidth: 150),
                      child: PostBoardSelectPopupMenu(
                        artistId: currentArtist.id,
                        refreshFunction: () {},
                      ),
                      // child: CustomDropdown<BoardModel>(
                      //     onChanged: (BoardModel? newValue) {
                      //       logger.d('newValue: ${newValue!.board_id}');
                      //       ref
                      //           .read(communityStateInfoProvider.notifier)
                      //           .setCurrentBoardId(
                      //               newValue.board_id,
                      //               newValue.is_official
                      //                   ? getLocaleTextFromJson(newValue.name)
                      //                   : newValue.name['minor']);
                      //     },
                      //     closedHeaderPadding: const EdgeInsets.symmetric(
                      //         horizontal: 16, vertical: 0),
                      //     decoration: CustomDropdownDecoration(
                      //       headerStyle: getTextStyle(
                      //           AppTypo.caption12R, AppColors.grey700),
                      //       closedFillColor: AppColors.grey00,
                      //       closedBorderRadius: BorderRadius.circular(16),
                      //       closedBorder:
                      //           Border.all(color: AppColors.grey300, width: 1),
                      //       closedSuffixIcon: const Icon(Icons.arrow_drop_down),
                      //       closedErrorBorder:
                      //           Border.all(color: AppColors.mint500, width: 1),
                      //       expandedSuffixIcon: const Icon(Icons.arrow_drop_up),
                      //       listItemStyle: getTextStyle(
                      //           AppTypo.caption12R, AppColors.grey700),
                      //       listItemDecoration: const ListItemDecoration(
                      //         splashColor: AppColors.grey400,
                      //         selectedColor: AppColors.grey200,
                      //       ),
                      //     ),
                      //     hideSelectedFieldWhenExpanded: false,
                      //     headerBuilder: (context, board, isOpen) {
                      //       return Text(
                      //         board.is_official
                      //             ? getLocaleTextFromJson(board.name)
                      //             : board.name['minor'],
                      //         style: getTextStyle(
                      //             AppTypo.caption12R, AppColors.grey700),
                      //         textAlign: TextAlign.center,
                      //       );
                      //     },
                      //     initialItem: initItem,
                      //     listItemBuilder: (context, board, isEnable, onTap) {
                      //       logger.d(board.board_id);
                      //       return Text(
                      //         board.is_official
                      //             ? getLocaleTextFromJson(board.name)
                      //             : board.name['minor'],
                      //         style: getTextStyle(
                      //             AppTypo.caption12R, AppColors.grey700),
                      //         textAlign: TextAlign.center,
                      //       );
                      //     },
                      //     items: snapshot.data),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => widget.onSave(isTemporary: true),
                child: Text(S.of(context).post_header_temporary_save,
                    style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
              ),
              SizedBox(width: 16.cw),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      backgroundColor: AppColors.grey00,
                      textStyle: getTextStyle(AppTypo.body14B),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                            color: AppColors.primary500, width: 1),
                      ),
                    ),
                    onPressed: () => widget.onSave(),
                    child: Text(S.of(context).post_header_publish,
                        style: getTextStyle(
                            AppTypo.body14B, AppColors.primary500))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
