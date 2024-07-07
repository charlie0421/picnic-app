import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/chat/rooms.dart';
import 'package:picnic_app/pages/pic/article_page.dart';

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
    return _buildGalleryTab(ref);
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
