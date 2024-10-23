import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/board_dropdown.dart';
import 'package:picnic_app/components/community/write/post_write_actions.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';

import '../../../generated/l10n.dart';

class PostWriteHeader extends ConsumerStatefulWidget {
  final Function(bool isTemporary) onSave;
  final bool isTitleValid;

  const PostWriteHeader({
    super.key,
    required this.onSave,
    required this.isTitleValid,
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
    logger.d('PostWriteHeader build');
    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));
    final currentBoard = ref.watch(
        communityStateInfoProvider.select((value) => value.currentBoard));
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BoardDropdown(),
          PostWriteActions(
            isTitleValid: widget.isTitleValid,
            onSave: widget.onSave,
          ),
        ],
      ),
    );
  }
}
