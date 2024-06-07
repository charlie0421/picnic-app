import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/chat/rooms.dart';
import 'package:picnic_app/pages/pic/article_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

class GalleryDetailPage extends ConsumerStatefulWidget {
  static const String routeName = '/gallery_detail_screen';

  final int galleryId;
  final String galleryName;

  const GalleryDetailPage(
      {super.key, required this.galleryId, required this.galleryName});

  @override
  ConsumerState<GalleryDetailPage> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends ConsumerState<GalleryDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(
            unselectedLabelColor: Colors.grey,
            controller: _tabController,
            indicatorWeight: 1,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(0),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              Align(
                  alignment: Alignment.center,
                  child: Text(Intl.message('label_gallery_tab_article'),
                      style: const TextStyle(
                        fontSize: 16,
                      ))),
              Align(
                  alignment: Alignment.center,
                  child: Text(Intl.message('label_gallery_tab_chat'),
                      style: const TextStyle(
                        fontSize: 16,
                      ))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGalleryTab(ref),
              _buildChatTab(ref),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGalleryTab(ref) {
    return ArticlePage(galleryId: widget.galleryId);
  }

  Widget _buildChatTab(ref) {
    return const RoomsPage();
  }
}

class GalleryDetailScreenArguments {
  final int galleryId;
  final String galleryName;

  GalleryDetailScreenArguments(
      {required this.galleryId, required this.galleryName});
}
