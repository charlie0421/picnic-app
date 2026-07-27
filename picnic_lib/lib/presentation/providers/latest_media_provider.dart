import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/latest_media_provider.g.dart';

@riverpod
class AsyncLatestMedia extends _$AsyncLatestMedia {
  static const int _limit = 6;

  @override
  Future<List<VideoInfo>> build() async {
    try {
      final response = await supabase
          .from('media')
          .select()
          .filter('deleted_at', 'is', null)
          .order('id', ascending: false)
          .limit(_limit);

      return response.map((data) {
        final videoId = data['video_id']?.toString() ?? '';
        return VideoInfo(
          id: data['id'] as int,
          videoId: videoId,
          videoUrl: data['video_url']?.toString() ?? '',
          title: Map<String, String>.from(data['title'] as Map),
          thumbnailUrl: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : null,
          channelTitle: '',
          channelId: '',
          channelThumbnail: '',
        );
      }).toList();
    } catch (e, s) {
      logger.e('latest media load error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
