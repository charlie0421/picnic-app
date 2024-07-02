import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/pic/pic.dart';
import 'package:picnic_app/providers/pic_provider.dart';
import 'package:picnic_app/ui/style.dart';

class LibraryPage extends ConsumerStatefulWidget {
  static const String routeName = '/gallery_detail_screen';

  const LibraryPage({
    super.key,
  });

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 1,
      length: 3,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(ref),
    );
  }

  AppBar _buildAppBar(context, WidgetRef ref) {
    return AppBar();
  }

  Widget _buildPage(ref) {
    return Column(
      children: [
        SizedBox(
          height: 43.w,
          child: TabBar(
            indicatorWeight: 1,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.0, color: AppColors.Grey900),
            ),
            controller: _tabController,
            tabs: [
              Text(S.of(context).label_library_tab_library,
                  style: const TextStyle(
                    fontSize: 16,
                  )),
              Text(S.of(context).label_library_tab_pic,
                  style: const TextStyle(
                    fontSize: 16,
                  )),
              Text(S.of(context).label_library_tab_ai_photo,
                  style: const TextStyle(
                    fontSize: 16,
                  )),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              _buildGalleryTab(ref),
              _buildPicTab(ref),
              _buildChatTab(ref),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGalleryTab(ref) {
    return Container();
  }

  Widget _buildPicTab(ref) {
    int picPageIndex = ref.watch(parmePageIndexProvider);
    Widget widget = const PicPage();

    return WillPopScope(
      onWillPop: () async {
        if (ref.watch(parmePageIndexProvider.notifier).state == 1) {
          ref.read(parmePageIndexProvider.notifier).state = 0;
          return false;
        } else if (ref.watch(picSelectedIndexProvider.notifier).state == 0) {
          return true;
        }
        return true;
      },
      child: widget,
    );
  }

  Widget _buildChatTab(ref) {
    return Container();
  }
}
