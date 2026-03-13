import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/my_artist_provider_helper.dart';

void main() {
  group('MyArtistProviderHelper.maxBookmarks', () {
    test('is 5', () {
      expect(MyArtistProviderHelper.maxBookmarks, 5);
    });
  });

  group('MyArtistProviderHelper.isBookmarkLimitReached', () {
    test('returns false when count is 0', () {
      expect(MyArtistProviderHelper.isBookmarkLimitReached(0), isFalse);
    });

    test('returns false when count is 1', () {
      expect(MyArtistProviderHelper.isBookmarkLimitReached(1), isFalse);
    });

    test('returns false when count is 4', () {
      expect(MyArtistProviderHelper.isBookmarkLimitReached(4), isFalse);
    });

    test('returns true when count is exactly 5', () {
      expect(MyArtistProviderHelper.isBookmarkLimitReached(5), isTrue);
    });

    test('returns true when count exceeds 5', () {
      expect(MyArtistProviderHelper.isBookmarkLimitReached(6), isTrue);
      expect(MyArtistProviderHelper.isBookmarkLimitReached(100), isTrue);
    });
  });
}
