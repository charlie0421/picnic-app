import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/video_info.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VoteMediaListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteMediaListPage({super.key});

  @override
  ConsumerState<VoteMediaListPage> createState() => _VoteMediaListPageState();
}

class _VoteMediaListPageState extends ConsumerState<VoteMediaListPage> {
  static const _pageSize = 10;

  final PagingController<int, VideoInfo> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
    });
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, VideoInfo>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<VideoInfo>(
        itemBuilder: (context, item, index) => VideoListItem(
          item: item,
          onTap: () {},
        ),
        firstPageErrorIndicatorBuilder: (context) {
          return SliverToBoxAdapter(
            child: ErrorView(
              context,
              error: _pagingController.error.toString(),
              retryFunction: () => _pagingController.refresh(),
              stackTrace: _pagingController.error is Error
                  ? (_pagingController.error as Error).stackTrace
                  : StackTrace.current,
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await supabase
          .from("media")
          .select()
          .order('id', ascending: false)
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1);

      final newItems = response.map((e) => VideoInfo.fromJson(e)).toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      _pagingController.error = e;
      rethrow;
    }
  }
}

class VideoListItem extends StatefulWidget {
  final VideoInfo item;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<VideoListItem> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final videoId = widget.item.video_id;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress == 0 ? 0 : progress / 100;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.youtube.com/embed/$videoId'));
  }

  Future<void> _launchYouTube(BuildContext context) async {
    final youtubeUrl = widget.item.video_url;
    final uri = Uri.parse(youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).post_cannot_open_youtube)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: AppColors.grey200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _loadingProgress,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary500),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${(_loadingProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: AppColors.primary500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getLocaleTextFromJson(widget.item.title),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                    ),
                    Text(
                      formatDateTimeYYYYMMDD(widget.item.created_at),
                      style:
                          getTextStyle(AppTypo.caption12M, AppColors.grey900),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.youtube,
                    color: Color.fromRGBO(255, 0, 0, 1)),
                onPressed: () => _launchYouTube(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
