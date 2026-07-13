import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncLatestMedia', () {
    setUp(() {
      setupMockSupabase({
        'media': [
          {'id': 2, 'video_id': 'abc', 'video_url': 'u', 'title': {'ko': 'v2'}, 'created_at': '2026-07-02T00:00:00Z'},
          {'id': 1, 'video_id': 'def', 'video_url': 'u', 'title': {'ko': 'v1'}, 'created_at': '2026-07-01T00:00:00Z'},
        ],
      });
    });
    tearDown(() => tearDownMockSupabase());

    test('maps media rows to VideoInfo with derived thumbnail', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncLatestMediaProvider.future);
      expect(result, isA<List<VideoInfo>>());
      expect(result.length, 2);
      expect(result.first.thumbnailUrl, contains('img.youtube.com/vi/'));
    });
  });
}
