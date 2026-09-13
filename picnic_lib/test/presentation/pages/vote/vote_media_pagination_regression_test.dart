import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_media_list_page.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  for (final count in [9, 10, 11, 20]) {
    testWidgets(
      'MEDIA stops paging after the terminal response for $count rows',
      (tester) async {
        final offsets = <int>[];
        testSupabaseClient = SupabaseClient(
          'https://pagination.invalid',
          'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            final offset = int.parse(
              request.url.queryParameters['offset'] ?? '0',
            );
            final limit = int.parse(
              request.url.queryParameters['limit'] ?? '10',
            );
            offsets.add(offset);
            final rows = [
              for (var i = offset; i < count && i < offset + limit; i++)
                {
                  'id': i + 1,
                  'video_id': 'video_$i',
                  'video_url': '',
                  'title': {'ko': '미디어 $i'},
                },
            ];
            return http.Response(
              jsonEncode(rows),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        final restoreErrors = suppressImageErrors();
        addTearDown(() {
          restoreErrors();
          testSupabaseClient = null;
        });

        await tester.pumpWidget(buildTestApp(const VoteMediaListPage()));
        await tester.pump();
        await tester.pump();
        final controller = tester
            .widget<PagingListener<int, VideoInfo>>(
              find.byType(PagingListener<int, VideoInfo>),
            )
            .controller;

        for (var i = 0; i < 5; i++) {
          controller.fetchNextPage();
          await tester.pump();
          await tester.pump();
        }

        expect(controller.value.items, hasLength(count));
        expect(controller.value.hasNextPage, isFalse);
        expect(
          offsets,
          count == 9
              ? [0]
              : count == 10
              ? [0, 10]
              : count == 11
              ? [0, 10]
              : [0, 10, 20],
        );
      },
    );
  }
}
