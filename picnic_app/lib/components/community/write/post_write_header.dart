import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/comminuty_navigation_provider.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

import '../../../generated/l10n.dart';

class PostWriteHeader extends ConsumerStatefulWidget {
  final VoidCallback onSave;

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
    final currentArtistId = ref.watch(communityNavigationInfoProvider
        .select((value) => value.currentArtistId));
    String currentBoardId = ref.watch(communityNavigationInfoProvider
        .select((value) => value.currentBoardId));

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            child: FutureBuilder(
                future: boards(ref, currentArtistId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    BoardModel? initItem;
                    if (currentBoardId.isNotEmpty) {
                      initItem = snapshot.data?.firstWhere(
                          (element) => element.board_id == currentBoardId);
                    } else {
                      initItem = snapshot.data?.first;
                    }
                    currentBoardId = initItem!.board_id;

                    return Container(
                      constraints:
                          const BoxConstraints(minWidth: 100, maxWidth: 150),
                      child: CustomDropdown<BoardModel>(
                          onChanged: (BoardModel? newValue) {
                            logger.d('newValue: ${newValue!.board_id}');
                            ref
                                .read(communityNavigationInfoProvider.notifier)
                                .setCurrentBoardId(
                                    newValue!.board_id,
                                    newValue.is_official
                                        ? getLocaleTextFromJson(newValue.name)
                                        : newValue.name['minor']);
                          },
                          closedHeaderPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          decoration: CustomDropdownDecoration(
                            headerStyle: getTextStyle(
                                AppTypo.caption12R, AppColors.grey700),
                            closedFillColor: AppColors.grey00,
                            closedBorderRadius: BorderRadius.circular(16),
                            closedBorder:
                                Border.all(color: AppColors.grey300, width: 1),
                            closedSuffixIcon: const Icon(Icons.arrow_drop_down),
                            closedErrorBorder:
                                Border.all(color: AppColors.mint500, width: 1),
                            expandedSuffixIcon: const Icon(Icons.arrow_drop_up),
                            listItemStyle: getTextStyle(
                                AppTypo.caption12R, AppColors.grey700),
                            listItemDecoration: const ListItemDecoration(
                              splashColor: AppColors.grey400,
                              selectedColor: AppColors.grey200,
                            ),
                          ),
                          hideSelectedFieldWhenExpanded: false,
                          headerBuilder: (context, board, isOpen) {
                            return Text(
                              board.is_official
                                  ? getLocaleTextFromJson(board.name)
                                  : board.name['minor'],
                              style: getTextStyle(
                                  AppTypo.caption12R, AppColors.grey700),
                              textAlign: TextAlign.center,
                            );
                          },
                          initialItem: initItem,
                          listItemBuilder: (context, board, isEnable, onTap) {
                            logger.d(board.board_id);
                            return Text(
                              board.is_official
                                  ? getLocaleTextFromJson(board.name)
                                  : board.name['minor'],
                              style: getTextStyle(
                                  AppTypo.caption12R, AppColors.grey700),
                              textAlign: TextAlign.center,
                            );
                          },
                          items: snapshot.data),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(S.of(context).post_header_temporary_save,
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
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
                    onPressed: widget.onSave,
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
