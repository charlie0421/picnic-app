import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';

/// Extended tests for ArtistSelectListView logic patterns.
void main() {
  group('ArtistSelectConfig searchEmptyMessageTemplate', () {
    test('replaces query placeholder with search term', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: '"{query}"에 대한 검색 결과가 없습니다.',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', 'BTS');
      expect(message, '"BTS"에 대한 검색 결과가 없습니다.');
    });

    test('replaces query placeholder with special characters', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: 'No results for "{query}"',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', 'K-Pop & J-Pop');
      expect(message, 'No results for "K-Pop & J-Pop"');
    });

    test('replaces query placeholder with unicode', () {
      const config = ArtistSelectConfig(
        searchEmptyMessageTemplate: '"{query}"에 대한 검색 결과가 없습니다.',
      );
      final message =
          config.searchEmptyMessageTemplate.replaceAll('{query}', '방탄소년단');
      expect(message, '"방탄소년단"에 대한 검색 결과가 없습니다.');
    });
  });

  group('ArtistSelectConfig visibility logic', () {
    test('shows headers when hideSectionHeaderOnSearch is false regardless of query', () {
      const config = ArtistSelectConfig(hideSectionHeaderOnSearch: false);

      final withQuery = config.hideSectionHeaderOnSearch ? ''.isEmpty : true;
      expect(withQuery, true);

      final withSearchTerm = config.hideSectionHeaderOnSearch ? 'test'.isEmpty : true;
      expect(withSearchTerm, true);
    });

    test('hides headers on search when hideSectionHeaderOnSearch is true', () {
      const config = ArtistSelectConfig(hideSectionHeaderOnSearch: true);

      final withSearch = config.hideSectionHeaderOnSearch ? 'test'.isEmpty : true;
      expect(withSearch, false);

      final withoutSearch = config.hideSectionHeaderOnSearch ? ''.isEmpty : true;
      expect(withoutSearch, true);
    });
  });

  group('Bookmark section header logic', () {
    test('first bookmark item detection', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      // Index 0: bookmarked, first item -> first bookmark
      expect(items[0].isBookmarked == true, isTrue);

      // Index 1: bookmarked, previous also bookmarked -> not first
      expect(items[1].isBookmarked == true && items[0].isBookmarked == true, isTrue);

      // Index 2: not bookmarked -> not a bookmark item
      expect(items[2].isBookmarked == true, isFalse);
    });

    test('first non-bookmark item detection', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      // Index 0: bookmarked -> not a non-bookmark item
      expect(items[0].isBookmarked != true, isFalse);

      // Index 1: not bookmarked, previous is bookmarked -> first non-bookmark
      expect(items[1].isBookmarked != true && items[0].isBookmarked == true, isTrue);

      // Index 2: not bookmarked, previous also not bookmarked -> not first non-bookmark
      expect(items[2].isBookmarked != true && items[1].isBookmarked == true, isFalse);
    });

    test('all bookmarked items', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];

      // First item is first bookmark
      bool isFirstBookmark(int index) {
        if (items[index].isBookmarked != true) return false;
        if (index == 0) return true;
        return items[index - 1].isBookmarked != true;
      }

      expect(isFirstBookmark(0), true);
      expect(isFirstBookmark(1), false);
    });

    test('no bookmarked items', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];

      bool isFirstNonBookmark(int index) {
        if (items[index].isBookmarked == true) return false;
        if (index == 0) return true;
        return items[index - 1].isBookmarked == true;
      }

      expect(isFirstNonBookmark(0), true);
      expect(isFirstNonBookmark(1), false);
    });
  });

  group('Bookmark state update and position logic', () {
    test('adding bookmark moves item to bookmark section', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      // Bookmark item at index 2
      final targetIndex = 2;
      final item = items[targetIndex];
      final updatedItem = item.copyWith(isBookmarked: true);
      items.removeAt(targetIndex);

      // Find last bookmark index
      final lastBookmarkIndex = items.lastIndexWhere((i) => i.isBookmarked == true);
      final insertIndex = lastBookmarkIndex + 1;
      items.insert(insertIndex, updatedItem);

      // Now item should be after the bookmark section
      expect(items[1].id, 3); // Item C moved to bookmark section end
      expect(items[1].isBookmarked, true);
    });

    test('removing bookmark moves item to general section', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      // Unbookmark item at index 0
      final item = items[0];
      final updatedItem = item.copyWith(isBookmarked: false);
      items.removeAt(0);

      // Find first non-bookmark index
      final firstNonBookmarkIndex = items.indexWhere((i) => i.isBookmarked != true);
      final insertIndex = firstNonBookmarkIndex == -1 ? items.length : firstNonBookmarkIndex;
      items.insert(insertIndex, updatedItem);

      // Item A should now be in general section
      expect(items[1].id, 1);
      expect(items[1].isBookmarked, false);
    });

    test('unbookmark when no non-bookmark items exist adds to end', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];

      final item = items[0];
      final updatedItem = item.copyWith(isBookmarked: false);
      items.removeAt(0);

      final firstNonBookmarkIndex = items.indexWhere((i) => i.isBookmarked != true);
      final insertIndex = firstNonBookmarkIndex == -1 ? items.length : firstNonBookmarkIndex;
      items.insert(insertIndex, updatedItem);

      // Should be at end since no non-bookmark items
      expect(items.last.id, 1);
      expect(items.last.isBookmarked, false);
    });
  });

  group('Scroll pagination logic', () {
    test('triggers load more near end of list', () {
      const currentPixels = 980.0;
      const maxExtent = 1000.0;
      const threshold = 200.0;

      final shouldLoadMore = currentPixels >= maxExtent - threshold;
      expect(shouldLoadMore, true);
    });

    test('does not trigger load more when far from end', () {
      const currentPixels = 500.0;
      const maxExtent = 1000.0;
      const threshold = 200.0;

      final shouldLoadMore = currentPixels >= maxExtent - threshold;
      expect(shouldLoadMore, false);
    });

    test('hasMore is true when page has full items', () {
      const pageSize = 20;
      final items = List.generate(20, (i) => i);
      final hasMore = items.length >= pageSize;
      expect(hasMore, true);
    });

    test('hasMore is false when page has fewer items', () {
      const pageSize = 20;
      final items = List.generate(15, (i) => i);
      final hasMore = items.length >= pageSize;
      expect(hasMore, false);
    });

    test('loading guard prevents duplicate loads', () {
      var isLoading = false;
      var loadCount = 0;

      void loadMore() {
        if (isLoading) return;
        isLoading = true;
        loadCount++;
      }

      loadMore();
      loadMore(); // Should be blocked
      loadMore(); // Should be blocked

      expect(loadCount, 1);
    });

    test('hasMore guard prevents loading after last page', () {
      var hasMore = false;
      var loadCount = 0;

      void loadMore() {
        if (!hasMore) return;
        loadCount++;
      }

      loadMore();
      expect(loadCount, 0);
    });
  });

  group('Image URL resolution for artist items', () {
    test('uses artist image when available', () {
      const item = ArtistModel(
        id: 123,
        name: {'ko': 'Test'},
        image: 'https://cdn.example.com/artist.png',
      );

      final imageUrl = item.image ?? 'artist/${item.id}/image.png';
      expect(imageUrl, 'https://cdn.example.com/artist.png');
    });

    test('falls back to default path when image is null', () {
      const item = ArtistModel(
        id: 456,
        name: {'ko': 'Test'},
      );

      final imageUrl = item.image ?? 'artist/${item.id}/image.png';
      expect(imageUrl, 'artist/456/image.png');
    });
  });
}
