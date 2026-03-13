import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_list_helper.dart';

void main() {
  group('ArtistListHelper.isFirstBookmarkItem', () {
    test('first item that is bookmarked returns true', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];
      expect(ArtistListHelper.isFirstBookmarkItem(items, 0), true);
    });

    test('second bookmarked item returns false', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];
      expect(ArtistListHelper.isFirstBookmarkItem(items, 1), false);
    });

    test('non-bookmarked item returns false', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
      ];
      expect(ArtistListHelper.isFirstBookmarkItem(items, 0), false);
    });

    test('bookmarked after non-bookmarked returns true', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];
      expect(ArtistListHelper.isFirstBookmarkItem(items, 1), true);
    });

    test('null isBookmarked treated as not bookmarked', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];
      expect(ArtistListHelper.isFirstBookmarkItem(items, 0), false);
      expect(ArtistListHelper.isFirstBookmarkItem(items, 1), true);
    });
  });

  group('ArtistListHelper.isFirstNonBookmarkItem', () {
    test('first non-bookmarked item at index 0 returns true', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
      ];
      expect(ArtistListHelper.isFirstNonBookmarkItem(items, 0), true);
    });

    test('non-bookmark after bookmark returns true', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];
      expect(ArtistListHelper.isFirstNonBookmarkItem(items, 1), true);
    });

    test('second non-bookmark returns false', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];
      expect(ArtistListHelper.isFirstNonBookmarkItem(items, 1), false);
    });

    test('bookmarked item returns false', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
      ];
      expect(ArtistListHelper.isFirstNonBookmarkItem(items, 0), false);
    });
  });

  group('ArtistListHelper.shouldShowSectionHeaders', () {
    test('shows headers when hideSectionHeaderOnSearch is false', () {
      expect(
        ArtistListHelper.shouldShowSectionHeaders(
          hideSectionHeaderOnSearch: false,
          searchQuery: 'test',
        ),
        true,
      );
    });

    test('hides headers on search when hideSectionHeaderOnSearch is true', () {
      expect(
        ArtistListHelper.shouldShowSectionHeaders(
          hideSectionHeaderOnSearch: true,
          searchQuery: 'test',
        ),
        false,
      );
    });

    test('shows headers when search is empty even with hide flag', () {
      expect(
        ArtistListHelper.shouldShowSectionHeaders(
          hideSectionHeaderOnSearch: true,
          searchQuery: '',
        ),
        true,
      );
    });
  });

  group('ArtistListHelper.reorderAfterBookmarkChange', () {
    test('bookmarking moves item to end of bookmark section', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 3,
        isBookmarked: true,
      );

      expect(result[0].id, 1);
      expect(result[1].id, 3);
      expect(result[1].isBookmarked, true);
      expect(result[2].id, 2);
    });

    test('unbookmarking moves item to start of general section', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
        const ArtistModel(id: 3, name: {'ko': 'C'}, isBookmarked: false),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 1,
        isBookmarked: false,
      );

      expect(result[0].id, 2); // remaining bookmark
      expect(result[1].id, 1); // unbookmarked, before other non-bookmark
      expect(result[1].isBookmarked, false);
      expect(result[2].id, 3);
    });

    test('unbookmark when no non-bookmark items adds to end', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: true),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 1,
        isBookmarked: false,
      );

      expect(result[0].id, 2);
      expect(result[1].id, 1);
      expect(result[1].isBookmarked, false);
    });

    test('bookmark when no bookmarks exist inserts at index 0', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 2,
        isBookmarked: true,
      );

      expect(result[0].id, 2);
      expect(result[0].isBookmarked, true);
      expect(result[1].id, 1);
    });

    test('returns same list when artistId not found', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 999,
        isBookmarked: true,
      );

      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('does not mutate original list', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
        const ArtistModel(id: 2, name: {'ko': 'B'}, isBookmarked: false),
      ];

      ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 2,
        isBookmarked: true,
      );

      expect(items.length, 2);
      expect(items[0].id, 1);
      expect(items[1].id, 2);
      expect(items[1].isBookmarked, false);
    });

    test('single item bookmark', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: false),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 1,
        isBookmarked: true,
      );

      expect(result.length, 1);
      expect(result[0].id, 1);
      expect(result[0].isBookmarked, true);
    });

    test('single item unbookmark', () {
      final items = [
        const ArtistModel(id: 1, name: {'ko': 'A'}, isBookmarked: true),
      ];

      final result = ArtistListHelper.reorderAfterBookmarkChange(
        items: items,
        artistId: 1,
        isBookmarked: false,
      );

      expect(result.length, 1);
      expect(result[0].id, 1);
      expect(result[0].isBookmarked, false);
    });
  });

  group('ArtistListHelper.resolveImageUrl', () {
    test('returns image when available', () {
      const item = ArtistModel(
        id: 123,
        name: {'ko': 'Test'},
        image: 'https://cdn.example.com/artist.png',
      );
      expect(ArtistListHelper.resolveImageUrl(item), 'https://cdn.example.com/artist.png');
    });

    test('falls back to default path when image is null', () {
      const item = ArtistModel(id: 456, name: {'ko': 'Test'});
      expect(ArtistListHelper.resolveImageUrl(item), 'artist/456/image.png');
    });
  });

  group('ArtistListHelper.shouldLoadMore', () {
    test('returns true near end of scroll', () {
      expect(
        ArtistListHelper.shouldLoadMore(
          currentPixels: 900,
          maxScrollExtent: 1000,
        ),
        true,
      );
    });

    test('returns false far from end', () {
      expect(
        ArtistListHelper.shouldLoadMore(
          currentPixels: 500,
          maxScrollExtent: 1000,
        ),
        false,
      );
    });

    test('returns true at exact threshold', () {
      expect(
        ArtistListHelper.shouldLoadMore(
          currentPixels: 800,
          maxScrollExtent: 1000,
          threshold: 200,
        ),
        true,
      );
    });

    test('custom threshold', () {
      expect(
        ArtistListHelper.shouldLoadMore(
          currentPixels: 850,
          maxScrollExtent: 1000,
          threshold: 100,
        ),
        false,
      );
    });
  });

  group('ArtistListHelper.hasMorePages', () {
    test('returns true when full page', () {
      expect(
        ArtistListHelper.hasMorePages(resultCount: 20, pageSize: 20),
        true,
      );
    });

    test('returns false when partial page', () {
      expect(
        ArtistListHelper.hasMorePages(resultCount: 15, pageSize: 20),
        false,
      );
    });

    test('returns false when empty result', () {
      expect(
        ArtistListHelper.hasMorePages(resultCount: 0, pageSize: 20),
        false,
      );
    });

    test('returns true when more than page size', () {
      expect(
        ArtistListHelper.hasMorePages(resultCount: 25, pageSize: 20),
        true,
      );
    });
  });
}
