import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/community/write/board_dropdown.dart';
import 'package:picnic_lib/presentation/widgets/community/write/post_write_actions.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

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
