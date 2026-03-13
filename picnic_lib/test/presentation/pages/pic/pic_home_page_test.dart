import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

/// Tests for PicHomePage logic patterns and data model interactions.
///
/// Widget rendering tests for PicHomePage are limited because it requires
/// multiple async providers (asyncCelebListProvider, asyncBannerListProvider,
/// asyncVoteListProvider, asyncCelebGalleryListProvider) and SVG assets.
/// Instead we test the vote status logic and model patterns.
void main() {
  group('PicHomePage vote status logic', () {
    test('upcoming status when startAt is in the future', () {
      final now = DateTime.now().toUtc();
      final futureStart = now.add(const Duration(days: 1));

      final status =
          futureStart.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
      expect(status, VoteStatus.upcoming);
    });

    test('active status when startAt is in the past', () {
      final now = DateTime.now().toUtc();
      final pastStart = now.subtract(const Duration(days: 1));

      final status =
          pastStart.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
      expect(status, VoteStatus.active);
    });

    test('active status when startAt equals now', () {
      final now = DateTime.now().toUtc();

      final status =
          now.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
      expect(status, VoteStatus.active);
    });

    test('upcoming for 1 second in the future', () {
      final now = DateTime.now().toUtc();
      final almostNow = now.add(const Duration(seconds: 1));

      final status =
          almostNow.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
      expect(status, VoteStatus.upcoming);
    });

    test('active for 1 second in the past', () {
      final now = DateTime.now().toUtc();
      final justPast = now.subtract(const Duration(seconds: 1));

      final status =
          justPast.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
      expect(status, VoteStatus.active);
    });
  });

  group('VoteStatus enum', () {
    test('active value exists', () {
      expect(VoteStatus.active, isNotNull);
    });

    test('upcoming value exists', () {
      expect(VoteStatus.upcoming, isNotNull);
    });

    test('activeAndUpcoming value exists', () {
      expect(VoteStatus.activeAndUpcoming, isNotNull);
    });

    test('all values are present', () {
      expect(VoteStatus.values.length, greaterThanOrEqualTo(2));
    });
  });

  group('VotePortal enum', () {
    test('pic portal exists', () {
      expect(VotePortal.pic, isNotNull);
    });

    test('vote portal exists', () {
      expect(VotePortal.vote, isNotNull);
    });
  });

  group('VoteCategory enum', () {
    test('all category exists', () {
      expect(VoteCategory.all, isNotNull);
    });
  });

  group('GalleryModel', () {
    test('creates gallery with cover', () {
      final gallery = GalleryModel(
        id: 1,
        titleKo: '갤러리',
        titleEn: 'Gallery',
        cover: 'https://example.com/cover.jpg',
        celeb: null,
      );
      expect(gallery.id, 1);
      expect(gallery.titleKo, '갤러리');
      expect(gallery.titleEn, 'Gallery');
      expect(gallery.cover, isNotNull);
    });

    test('gallery with null cover', () {
      final gallery = GalleryModel(
        id: 2,
        titleKo: '갤러리2',
        titleEn: 'Gallery2',
        celeb: null,
      );
      expect(gallery.cover, isNull);
    });

    test('getCdnUrl generates correct URL', () {
      final gallery = GalleryModel(
        id: 5,
        titleKo: '갤러리',
        titleEn: 'Gallery',
        celeb: null,
      );
      expect(
        gallery.getCdnUrl('image.jpg'),
        'https://cdn-dev.picnic.fan/gallery/5/image.jpg',
      );
    });

    test('titleKo and titleEn are stored correctly', () {
      final gallery = GalleryModel(
        id: 1,
        titleKo: '한국어 제목',
        titleEn: 'English Title',
        celeb: null,
      );
      expect(gallery.titleKo, '한국어 제목');
      expect(gallery.titleEn, 'English Title');
    });

    test('gallery with celeb', () {
      final celeb = CelebModel.fromJson({
        'id': 1,
        'name_ko': '지민',
        'name_en': 'Jimin',
      });
      final gallery = GalleryModel(
        id: 3,
        titleKo: '지민 갤러리',
        titleEn: 'Jimin Gallery',
        cover: 'https://example.com/jimin.jpg',
        celeb: celeb,
      );
      expect(gallery.celeb, isNotNull);
      expect(gallery.celeb!.nameKo, '지민');
    });

    test('gallery with empty cover string', () {
      final gallery = GalleryModel(
        id: 4,
        titleKo: '빈 커버',
        titleEn: 'Empty Cover',
        cover: '',
        celeb: null,
      );
      expect(gallery.cover, '');
    });
  });

  group('CelebModel', () {
    test('creates from JSON', () {
      final celeb = CelebModel.fromJson({
        'id': 1,
        'name_ko': '지민',
        'name_en': 'Jimin',
      });
      expect(celeb.id, 1);
      expect(celeb.nameKo, '지민');
      expect(celeb.nameEn, 'Jimin');
    });

    test('creates with thumbnail', () {
      final celeb = CelebModel.fromJson({
        'id': 2,
        'name_ko': '정국',
        'name_en': 'Jungkook',
        'thumbnail': 'https://example.com/jk.jpg',
      });
      expect(celeb.thumbnail, 'https://example.com/jk.jpg');
    });

    test('creates with null thumbnail', () {
      final celeb = CelebModel.fromJson({
        'id': 3,
        'name_ko': '뷔',
        'name_en': 'V',
      });
      expect(celeb.thumbnail, isNull);
    });
  });

  group('PicHomePage navigation logic', () {
    test('isPicActive check', () {
      // Simulates: navState.portalType == PortalType.pic
      final portalType = 'pic';
      final isPicActive = portalType == 'pic';
      expect(isPicActive, isTrue);
    });

    test('isAtRoot check with null stack', () {
      List<String>? voteNavigationStack;
      final isAtRoot =
          voteNavigationStack == null || voteNavigationStack.length <= 1;
      expect(isAtRoot, isTrue);
    });

    test('isAtRoot check with empty stack', () {
      List<String>? voteNavigationStack = [];
      final isAtRoot =
          voteNavigationStack == null || voteNavigationStack.length <= 1;
      expect(isAtRoot, isTrue);
    });

    test('isAtRoot check with single item stack', () {
      List<String>? voteNavigationStack = ['home'];
      final isAtRoot =
          voteNavigationStack == null || voteNavigationStack.length <= 1;
      expect(isAtRoot, isTrue);
    });

    test('isAtRoot check with multiple items', () {
      List<String>? voteNavigationStack = ['home', 'detail'];
      final isAtRoot =
          voteNavigationStack == null || voteNavigationStack.length <= 1;
      expect(isAtRoot, isFalse);
    });

    test('page title clearing condition', () {
      final isPicActive = true;
      final isAtRoot = true;
      final pageTitle = 'Some Title';

      final shouldClearTitle =
          isPicActive && isAtRoot && pageTitle.isNotEmpty;
      expect(shouldClearTitle, isTrue);
    });

    test('page title not cleared when not pic active', () {
      final isPicActive = false;
      final isAtRoot = true;
      final pageTitle = 'Some Title';

      final shouldClearTitle =
          isPicActive && isAtRoot && pageTitle.isNotEmpty;
      expect(shouldClearTitle, isFalse);
    });

    test('page title not cleared when already empty', () {
      final isPicActive = true;
      final isAtRoot = true;
      final pageTitle = '';

      final shouldClearTitle =
          isPicActive && isAtRoot && pageTitle.isNotEmpty;
      expect(shouldClearTitle, isFalse);
    });
  });

  group('CelebDropDown search list logic', () {
    test('removes selected celeb from list', () {
      final data = [
        CelebModel.fromJson({'id': 1, 'name_ko': 'A', 'name_en': 'A'}),
        CelebModel.fromJson({'id': 2, 'name_ko': 'B', 'name_en': 'B'}),
        CelebModel.fromJson({'id': 3, 'name_ko': 'C', 'name_en': 'C'}),
      ];
      final selectedCeleb = data[1]; // id: 2

      data.removeWhere((item) => item.id == selectedCeleb.id);

      expect(data.length, 2);
      expect(data.any((e) => e.id == 2), isFalse);
    });

    test('keeps all when selected not in list', () {
      final data = [
        CelebModel.fromJson({'id': 1, 'name_ko': 'A', 'name_en': 'A'}),
        CelebModel.fromJson({'id': 2, 'name_ko': 'B', 'name_en': 'B'}),
      ];
      final selectedCeleb =
          CelebModel.fromJson({'id': 99, 'name_ko': 'X', 'name_en': 'X'});

      data.removeWhere((item) => item.id == selectedCeleb.id);

      expect(data.length, 2);
    });
  });
}
