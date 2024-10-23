import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/common/post_board_select_popup_menu.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/ui.dart';

class BoardDropdown extends ConsumerStatefulWidget {
  const BoardDropdown({super.key});

  @override
  ConsumerState<BoardDropdown> createState() => _BoardDropdownState();
}

class _BoardDropdownState extends ConsumerState<BoardDropdown> {
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

    return SizedBox(
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
            return Container(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
              child: PostBoardSelectPopupMenu(
                artistId: currentArtist.id,
                refreshFunction: () {},
              ),
            );
          } else {
            return SizedBox(height: 32, child: buildLoadingOverlay());
          }
        },
      ),
    );
  }
}
