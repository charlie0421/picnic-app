import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/pages/article_page.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';
import 'package:prame_app/ui/style.dart';

class GalleryDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/gallery_detail_screen';

  final int galleryId;
  final String galleryName;

  const GalleryDetailScreen(
      {super.key, required this.galleryId, required this.galleryName});

  @override
  ConsumerState<GalleryDetailScreen> createState() =>
      _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends ConsumerState<GalleryDetailScreen>
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
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      bottomNavigationBar: buildBottomNavigationBar(ref),
      body: _buildPage(ref),
    );
  }

  AppBar _buildAppBar(context, WidgetRef ref) {
    return AppBar(
      title: Text(
        widget.galleryName,
        style: getTextStyle(AppTypo.UI20B, AppColors.Gray900),
      ),
    );
  }

  Widget _buildPage(ref) {
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
                  child: Text(Intl.message('label_gallery_tab_gallery'),
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
    return Container();
  }
}

class GalleryDetailScreenArguments {
  final int galleryId;
  final String galleryName;

  GalleryDetailScreenArguments(
      {required this.galleryId, required this.galleryName});
}
