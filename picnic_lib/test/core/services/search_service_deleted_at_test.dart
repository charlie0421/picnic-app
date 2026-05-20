import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/supabase_options.dart';

/// Regression test for soft-deleted artists leaking into candidate/search
/// results (e.g. duplicate "이채영" where the corrected entry was soft-deleted
/// but kept showing up in 투표 후보 신청 / artist search).
///
/// The shared mock returns every row regardless of query params, so these
/// tests assert at the PostgREST request level that every artist search /
/// selection query carries the `deleted_at=is.null` filter.
void main() {
  group('SearchService excludes soft-deleted artists from search/selection', () {
    late List<Uri> requests;

    setUp(() {
      SearchService.clearAllCache();
      requests = [];
      final mockClient = MockClient((request) async {
        final uri = request.url;
        if (uri.path.contains('/rest/v1/')) {
          requests.add(uri);
        }
        return http.Response(
          '[]',
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-0/*',
          },
        );
      });
      testSupabaseClient = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key-for-testing-purposes-only',
        httpClient: mockClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    });

    tearDown(() {
      testSupabaseClient = null;
      SearchService.clearAllCache();
    });

    List<Uri> requestsForTable(String table) => requests
        .where((u) => u.path.split('/rest/v1/').last == table)
        .toList();

    bool allFilterDeletedAt(List<Uri> uris) =>
        uris.isNotEmpty && uris.every((u) => u.query.contains('deleted_at=is.null'));

    test('searchArtistsFast text search filters deleted_at (reported bug)',
        () async {
      await SearchService.searchArtistsFast(query: '이채영');

      final artistReqs = requestsForTable('artist');
      expect(artistReqs, isNotEmpty,
          reason: 'a query against the artist table should be issued');
      expect(allFilterDeletedAt(artistReqs), isTrue,
          reason: 'artist candidate search must exclude soft-deleted artists');
    });

    test('searchArtistsFast empty query (default list) filters deleted_at',
        () async {
      await SearchService.searchArtistsFast(query: '');

      expect(allFilterDeletedAt(requestsForTable('artist')), isTrue,
          reason: 'default artist list must exclude soft-deleted artists');
    });

    test('searchArtists name search filters deleted_at', () async {
      await SearchService.searchArtists(query: 'Jimin', useCache: false);

      expect(allFilterDeletedAt(requestsForTable('artist')), isTrue,
          reason: 'artist name search must exclude soft-deleted artists');
    });

    test('searchArtists Korean-initial search filters deleted_at', () async {
      await SearchService.searchArtists(
        query: 'ㅈ',
        useCache: false,
        supportKoreanInitials: true,
      );

      expect(allFilterDeletedAt(requestsForTable('artist')), isTrue,
          reason: 'Korean-initial artist search must exclude soft-deleted '
              'artists (it fetches the full list before local filtering)');
    });

    test('searchArtists group search excludes deleted groups and artists',
        () async {
      await SearchService.searchArtists(query: 'aespa', useCache: false);

      expect(allFilterDeletedAt(requestsForTable('artist_group')), isTrue,
          reason: 'group-name search must exclude soft-deleted groups');
      expect(allFilterDeletedAt(requestsForTable('artist')), isTrue,
          reason: 'artists fetched by group must exclude soft-deleted artists');
    });
  });
}
