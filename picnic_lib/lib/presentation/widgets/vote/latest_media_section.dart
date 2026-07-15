import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/grid_two_column.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher.dart';

/// 홈 화면 최신 미디어(유튜브 영상) 2열 그리드 섹션.
///
/// 리워드 섹션과 동일한 [GridTwoColumn](순수 레이아웃) 규격을 사용한다.
/// 홈 [ListView] 안에서 중첩 스크롤 없이 여러 줄을 노출한다.
class LatestMediaSection extends ConsumerWidget {
  const LatestMediaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(asyncLatestMediaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Text(
            AppLocalizations.of(context).nav_media,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        const SizedBox(height: 16),
        mediaAsync.when(
          loading: () => const SizedBox(height: 100),
          error: (e, s) => const SizedBox.shrink(),
          data: (items) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridTwoColumn(
              childAspectRatio: 1.45,
              children: [
                for (final item in items) _mediaCard(item),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mediaCard(VideoInfo item) {
    final title = getLocaleTextFromJson(item.title);
    return GestureDetector(
      onTap: () => _launch(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PicnicCachedNetworkImage(
              key: ValueKey('latest_media_${item.id}'),
              imageUrl: item.thumbnailUrl,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 30,
                color: AppColors.grey900.withValues(alpha: 0.7),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: _artistEmphasizedTitle(title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 미디어 제목 안의 `#아티스트` 해시태그를 강조(민트·볼드)해 렌더링한다.
  /// 예: "7월은 #지윤 의 달💙" → "#지윤" 부분만 강조.
  Widget _artistEmphasizedTitle(String title) {
    final base = getTextStyle(AppTypo.body14R, Colors.white);
    final emphasis = getTextStyle(AppTypo.body14B, AppColors.secondary500);
    final tag = RegExp(r'#[^\s#]+');
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in tag.allMatches(title)) {
      if (m.start > last) {
        spans.add(TextSpan(text: title.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(text: m.group(0), style: emphasis));
      last = m.end;
    }
    if (last < title.length) {
      spans.add(TextSpan(text: title.substring(last), style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: title, style: base));
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _launch(VideoInfo item) async {
    final videoId = item.videoId;
    final appUrl = Uri.parse('vnd.youtube://watch?v=$videoId');
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      logger.e('Could not launch video URL');
    }
  }
}
