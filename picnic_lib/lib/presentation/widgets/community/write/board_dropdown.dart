import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_board_select_popup_menu.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

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
    if (currentArtist == null) {
      return const SizedBox();
    }
    return PostBoardSelectPopupMenu(
      artistId: currentArtist.id,
      refreshFunction: () {},
    );
  }
}
