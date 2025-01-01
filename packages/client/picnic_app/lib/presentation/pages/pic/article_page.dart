import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/presentation/widgets/article/article_list.dart';

class ArticlePage extends ConsumerStatefulWidget {
  final int galleryId;

  const ArticlePage({super.key, required this.galleryId});

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: ArticleSortWidget(
        //     galleryId: widget.galleryId,
        //   ),
        // ),
        const SizedBox(
          height: 20,
        ),
        Expanded(child: ArticleList(widget.galleryId)),
      ],
    );
  }
}
