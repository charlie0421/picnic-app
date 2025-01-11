// lib/components/vote/media/video_list_item.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoListItem extends StatelessWidget {
  final VideoInfo item;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 웹 환경에서는 임시 UI 표시
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            title: Text(getLocaleTextFromJson(item.title)),
            subtitle: Text('웹 환경에서는 아직 지원되지 않는 기능입니다'),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchYouTube(item.videoUrl),
            ),
          ),
        ),
      );
    }

    // 기존 모바일용 구현은 별도 파일로 분리
    return _MobileVideoListItem(item: item, onTap: onTap);
  }

  Future<void> _launchYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// 모바일 전용 구현은 별도 위젯으로 분리
class _MobileVideoListItem extends StatefulWidget {
  final VideoInfo item;
  final VoidCallback onTap;

  const _MobileVideoListItem({
    required this.item,
    required this.onTap,
  });

  @override
  State<_MobileVideoListItem> createState() => _MobileVideoListItemState();
}

class _MobileVideoListItemState extends State<_MobileVideoListItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Text(getLocaleTextFromJson(widget.item.title)),
      ),
    );
  }
}
