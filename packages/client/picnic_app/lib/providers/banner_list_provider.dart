import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/models/common/banner.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import '../util/logger.dart';

part '../generated/providers/banner_list_provider.g.dart';

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('banner')
        .select('id, title, thumbnail, image, duration')
        .eq('location', location)
        .or('and(start_at.lte.${now.toIso8601String()},or(end_at.gte.${now.toIso8601String()},end_at.is.null)),and(start_at.is.null,end_at.is.null)')
        .order('order', ascending: true)
        .order('start_at', ascending: false);

    return response.map((e) => BannerModel.fromJson(e)).toList();
  }

  Future<int?> _getGifDuration(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(Environment.cdnUrl + imageUrl));
      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(response.bodyBytes);
        int totalDuration = 0;
        for (int i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          totalDuration += frame.duration.inMilliseconds;
          frame.image.dispose();
        }
        codec.dispose();
        if (totalDuration < 100 * codec.frameCount) {
          totalDuration = 100 * codec.frameCount;
        }
        logger.d('GIF duration: $totalDuration');
        return totalDuration + 500;
      }
    } catch (e, s) {
      logger.e('Error getting GIF duration: $e', stackTrace: s);
    }
    return null;
  }
}
