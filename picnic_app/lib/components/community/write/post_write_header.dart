import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/common/post_board_select_popup_menu.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

import '../../../generated/l10n.dart';

class PostWriteHeader extends ConsumerStatefulWidget {
  final Function(bool isTemporary) onSave;
  final bool isTitleValid;

  const PostWriteHeader({
    Key? key,
    required this.onSave,
    required this.isTitleValid,
  }) : super(key: key);

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
                          (element) => element.boardId == currentBoard.boardId,
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
                onTap: () => widget.isTitleValid
                    ? widget.onSave(true)
                    : showSimpleDialog(
                        content: '제목을 입력해 주세요.',
                        onOk: () => Navigator.of(context).pop(),
                      ),
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
                    onPressed: widget.isTitleValid
                        ? () => widget.onSave(false)
                        : () => showSimpleDialog(
                              content: '제목을 입력해 주세요.',
                              onOk: () => Navigator.of(context).pop(),
                            ),
                    child: Text(
                      S.of(context).post_header_publish,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
