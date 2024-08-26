import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PostListPage extends ConsumerStatefulWidget {
  const PostListPage(this.boardId, {super.key});
  final pageName = 'PostListPage';
  final String boardId;
  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: true, showBottomNavigation: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PostListPage(widget.boardId);
  }
}
