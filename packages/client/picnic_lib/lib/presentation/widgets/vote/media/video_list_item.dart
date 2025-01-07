// lib/components/vote/media/video_list_item.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/common/webview/video_webview.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  late final WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewProvider = createWebViewProvider(
      videoId: widget.item.videoId,
      onLoadingChanged: (loading) {
        if (mounted) {
          setState(() {
            _isLoading = loading;
          });
        }
      },
      onProgressChanged: (progress) {
        if (mounted) {
          setState(() {
            _loadingProgress = progress;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(VideoListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.videoId != widget.item.videoId) {
      _webViewProvider.dispose();
      _initWebView();
    }
  }

  @override
  void dispose() {
    _webViewProvider.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube(BuildContext context) async {
    final youtubeUrl = widget.item.videoUrl;
    final uri = Uri.parse(youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SnackbarUtil().showSnackbar(Intl.message('post_cannot_open_youtube'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                KeyedSubtree(
                  key: ValueKey('webview-${widget.item.videoId}'),
                  child: _webViewProvider.build(context),
                ),
                if (_isLoading)
                  Container(
                    color: AppColors.grey200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _loadingProgress,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary500),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${(_loadingProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: AppColors.primary500),
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
                      formatDateTimeYYYYMMDD(widget.item.createdAt),
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
