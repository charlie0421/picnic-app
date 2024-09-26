import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/post_write_view.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PostWritePage extends ConsumerStatefulWidget {
  const PostWritePage({super.key});

  @override
  ConsumerState<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends ConsumerState<PostWritePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false, showTopMenu: true, showBottomNavigation: false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const PostWriteView();
  }
}
