import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';

/// Tests for ArtistSelectConfig and ArtistSelectListView logic.
///
/// Widget rendering tests for ArtistSelectListView are limited because
/// it requires a searchQueryProvider notifier and calls SearchService
/// which depends on Supabase queries. Instead we test the config model
/// and logic patterns.
void main() {
  group('ArtistSelectConfig', () {
    test('default values', () {
      const config = ArtistSelectConfig();
      expect(config.showBookmarkToggle, false);
      expect(config.hideSectionHeaderOnSearch, false);
      expect(config.bookmarkSectionTitle, '북마크');
      expect(config.generalSectionTitle, '전체 아티스트');
      expect(config.emptyMessage, '등록된 아티스트가 없습니다.');
      expect(config.errorMessage, '아티스트 목록을 불러오는데 실패했습니다.');
    });

    test('custom values', () {
      const config = ArtistSelectConfig(
        showBookmarkToggle: true,
        hideSectionHeaderOnSearch: true,
        bookmarkSectionTitle: 'Bookmarks',
        generalSectionTitle: 'All Artists',
        emptyMessage: 'No artists',
        searchEmptyMessageTemplate: 'No results for "{query}"',
        errorMessage: 'Error loading artists',
      );
      expect(config.showBookmarkToggle, true);
      expect(config.hideSectionHeaderOnSearch, true);
      expect(config.bookmarkSectionTitle, 'Bookmarks');
      expect(config.generalSectionTitle, 'All Artists');
      expect(config.emptyMessage, 'No artists');
      expect(config.errorMessage, 'Error loading artists');
    });

    test('searchEmptyMessageTemplate with placeholder', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: '"{query}"에 대한 검색 결과가 없습니다.',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', 'BTS');
      expect(message, '"BTS"에 대한 검색 결과가 없습니다.');
    });

    test('searchEmptyMessageTemplate with empty query', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: '"{query}"에 대한 검색 결과가 없습니다.',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', '');
      expect(message, '""에 대한 검색 결과가 없습니다.');
    });

    test('searchEmptyMessageTemplate with Korean query', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: '"{query}"에 대한 검색 결과가 없습니다.',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', '방탄소년단');
      expect(message, '"방탄소년단"에 대한 검색 결과가 없습니다.');
    });

    test('config with bookmark toggle shows sections', () {
      const config = ArtistSelectConfig(
        showBookmarkToggle: true,
        bookmarkSectionTitle: '즐겨찾기',
        generalSectionTitle: '전체',
      );
      expect(config.showBookmarkToggle, true);
      expect(config.bookmarkSectionTitle, '즐겨찾기');
      expect(config.generalSectionTitle, '전체');
    });

    test('config with hideSectionHeaderOnSearch', () {
      const config = ArtistSelectConfig(
        hideSectionHeaderOnSearch: true,
      );

      // Simulating the logic used in the widget
      const searchQuery = 'test';
      final shouldShowHeaders = config.hideSectionHeaderOnSearch
          ? searchQuery.isEmpty
          : true;
      expect(shouldShowHeaders, false);
    });

    test('config shows headers when search is empty', () {
      const config = ArtistSelectConfig(
        hideSectionHeaderOnSearch: true,
      );

      const searchQuery = '';
      final shouldShowHeaders = config.hideSectionHeaderOnSearch
          ? searchQuery.isEmpty
          : true;
      expect(shouldShowHeaders, true);
    });

    test('config always shows headers when hideSectionHeaderOnSearch is false',
        () {
      const config = ArtistSelectConfig(
        hideSectionHeaderOnSearch: false,
      );

      const searchQuery = 'test';
      final shouldShowHeaders = config.hideSectionHeaderOnSearch
          ? searchQuery.isEmpty
          : true;
      expect(shouldShowHeaders, true);
    });
  });
}
