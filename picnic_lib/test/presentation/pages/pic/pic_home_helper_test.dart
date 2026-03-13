import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_helper.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

void main() {
  group('PicHomeHelper.determineVoteStatus', () {
    test('returns upcoming when startAt is in the future', () {
      final now = DateTime.utc(2026, 3, 13, 12, 0);
      final startAt = DateTime.utc(2026, 3, 14, 12, 0);
      expect(
        PicHomeHelper.determineVoteStatus(startAt: startAt, now: now),
        VoteStatus.upcoming,
      );
    });

    test('returns active when startAt is in the past', () {
      final now = DateTime.utc(2026, 3, 13, 12, 0);
      final startAt = DateTime.utc(2026, 3, 12, 12, 0);
      expect(
        PicHomeHelper.determineVoteStatus(startAt: startAt, now: now),
        VoteStatus.active,
      );
    });

    test('returns active when startAt equals now', () {
      final now = DateTime.utc(2026, 3, 13, 12, 0);
      expect(
        PicHomeHelper.determineVoteStatus(startAt: now, now: now),
        VoteStatus.active,
      );
    });

    test('returns upcoming when startAt is 1 second in the future', () {
      final now = DateTime.utc(2026, 3, 13, 12, 0, 0);
      final startAt = DateTime.utc(2026, 3, 13, 12, 0, 1);
      expect(
        PicHomeHelper.determineVoteStatus(startAt: startAt, now: now),
        VoteStatus.upcoming,
      );
    });

    test('returns active when startAt is 1 second in the past', () {
      final now = DateTime.utc(2026, 3, 13, 12, 0, 1);
      final startAt = DateTime.utc(2026, 3, 13, 12, 0, 0);
      expect(
        PicHomeHelper.determineVoteStatus(startAt: startAt, now: now),
        VoteStatus.active,
      );
    });
  });

  group('PicHomeHelper.shouldClearTitle', () {
    test('returns true when all conditions met', () {
      expect(
        PicHomeHelper.shouldClearTitle(
          isPicActive: true,
          isAtRoot: true,
          currentTitle: 'Some Title',
        ),
        true,
      );
    });

    test('returns false when not PIC active', () {
      expect(
        PicHomeHelper.shouldClearTitle(
          isPicActive: false,
          isAtRoot: true,
          currentTitle: 'Some Title',
        ),
        false,
      );
    });

    test('returns false when not at root', () {
      expect(
        PicHomeHelper.shouldClearTitle(
          isPicActive: true,
          isAtRoot: false,
          currentTitle: 'Some Title',
        ),
        false,
      );
    });

    test('returns false when title is already empty', () {
      expect(
        PicHomeHelper.shouldClearTitle(
          isPicActive: true,
          isAtRoot: true,
          currentTitle: '',
        ),
        false,
      );
    });

    test('returns false when all conditions false', () {
      expect(
        PicHomeHelper.shouldClearTitle(
          isPicActive: false,
          isAtRoot: false,
          currentTitle: '',
        ),
        false,
      );
    });
  });

  group('PicHomeHelper.filterOutSelectedCeleb', () {
    test('filters out the selected item', () {
      final items = [1, 2, 3, 4, 5];
      final result = PicHomeHelper.filterOutSelectedCeleb(
        celebs: items,
        selectedId: 3,
        getId: (item) => item,
      );
      expect(result, [1, 2, 4, 5]);
    });

    test('returns all items when selected not in list', () {
      final items = [1, 2, 3];
      final result = PicHomeHelper.filterOutSelectedCeleb(
        celebs: items,
        selectedId: 99,
        getId: (item) => item,
      );
      expect(result, [1, 2, 3]);
    });

    test('returns empty list when only item is selected', () {
      final items = [1];
      final result = PicHomeHelper.filterOutSelectedCeleb(
        celebs: items,
        selectedId: 1,
        getId: (item) => item,
      );
      expect(result, isEmpty);
    });

    test('returns empty list for empty input', () {
      final result = PicHomeHelper.filterOutSelectedCeleb<int>(
        celebs: [],
        selectedId: 1,
        getId: (item) => item,
      );
      expect(result, isEmpty);
    });

    test('does not mutate original list', () {
      final items = [1, 2, 3];
      PicHomeHelper.filterOutSelectedCeleb(
        celebs: items,
        selectedId: 2,
        getId: (item) => item,
      );
      expect(items, [1, 2, 3]);
    });

    test('works with string IDs', () {
      final items = ['a', 'b', 'c'];
      final result = PicHomeHelper.filterOutSelectedCeleb(
        celebs: items,
        selectedId: 'b',
        getId: (item) => item,
      );
      expect(result, ['a', 'c']);
    });
  });

  group('PicHomeHelper.getGalleryTitle', () {
    test('returns Korean title for ko locale', () {
      expect(
        PicHomeHelper.getGalleryTitle('English', 'Korean', 'ko'),
        'Korean',
      );
    });

    test('returns English title for non-ko locale', () {
      expect(
        PicHomeHelper.getGalleryTitle('English', 'Korean', 'en'),
        'English',
      );
    });

    test('falls back to English when Korean is null', () {
      expect(
        PicHomeHelper.getGalleryTitle('English', null, 'ko'),
        'English',
      );
    });

    test('falls back to Korean when English is null', () {
      expect(
        PicHomeHelper.getGalleryTitle(null, 'Korean', 'en'),
        'Korean',
      );
    });

    test('returns empty string when both are null', () {
      expect(
        PicHomeHelper.getGalleryTitle(null, null, 'en'),
        '',
      );
    });
  });
}
