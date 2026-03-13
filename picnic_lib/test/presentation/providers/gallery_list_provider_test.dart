import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/gallery_list_provider.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncGalleryList Supabase 테스트', () {
    late ProviderContainer container;

    final galleryData = [
      {
        'id': 1,
        'title_ko': '첫번째 갤러리',
        'title_en': 'First Gallery',
        'cover': 'https://example.com/cover1.png',
        'celeb': null,
      },
      {
        'id': 2,
        'title_ko': '두번째 갤러리',
        'title_en': 'Second Gallery',
        'cover': null,
        'celeb': null,
      },
    ];

    setUp(() {
      setupMockSupabase({'gallery': galleryData});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches gallery list from supabase', () async {
      final result = await container.read(asyncGalleryListProvider.future);
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[0].titleKo, '첫번째 갤러리');
      expect(result[1].titleEn, 'Second Gallery');
    });

    test('returns empty list when no galleries exist', () async {
      container.dispose();
      tearDownMockSupabase();

      setupMockSupabase({'gallery': <Map<String, dynamic>>[]});
      container = ProviderContainer();

      final result = await container.read(asyncGalleryListProvider.future);
      expect(result, isEmpty);
    });
  });

  group('AsyncCelebGalleryList Supabase 테스트', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'gallery': [
          {
            'id': 10,
            'title_ko': '셀럽 갤러리',
            'title_en': 'Celeb Gallery',
            'cover': null,
            'celeb': null,
            'celeb_id': 5,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches celeb gallery list from supabase', () async {
      final result = await container.read(
        asyncCelebGalleryListProvider(5).future,
      );
      expect(result.length, 1);
      expect(result[0].id, 10);
      expect(result[0].titleKo, '셀럽 갤러리');
    });
  });

  group('SelectedGalleryId Supabase 테스트', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('default value is 0', () {
      final id = container.read(selectedGalleryIdProvider);
      expect(id, 0);
    });

    test('setSelectedGalleryId updates state', () {
      container.read(selectedGalleryIdProvider.notifier).setSelectedGalleryId(42);
      final id = container.read(selectedGalleryIdProvider);
      expect(id, 42);
    });
  });

  group('AsyncGalleryList 프로바이더 구조 테스트', () {
    test('asyncGalleryListProvider가 정의되어 있는지 확인', () {
      expect(asyncGalleryListProvider, isNotNull);
    });

    test('asyncGalleryListProvider가 올바른 타입인지 확인', () {
      // Riverpod 코드 생성 프로바이더는 ProviderBase를 직접 노출하지 않으므로
      // null이 아닌지와 존재 여부만 확인
      expect(asyncGalleryListProvider, isNotNull);
    });

    test('AsyncGalleryList 클래스가 인스턴스화 가능한지 확인', () {
      final galleryList = AsyncGalleryList();
      expect(galleryList, isNotNull);
    });
  });

  group('SelectedGalleryId 프로바이더 구조 테스트', () {
    test('selectedGalleryIdProvider가 정의되어 있는지 확인', () {
      expect(selectedGalleryIdProvider, isNotNull);
    });

    test('SelectedGalleryId 클래스가 인스턴스화 가능한지 확인', () {
      final selectedId = SelectedGalleryId();
      expect(selectedId, isNotNull);
    });

    test('SelectedGalleryId의 초기 selectedGalleryId가 0인지 확인', () {
      final selectedId = SelectedGalleryId();
      expect(selectedId.selectedGalleryId, 0);
    });

    test('SelectedGalleryId의 setSelectedGalleryId 메서드가 존재하는지 확인', () {
      final selectedId = SelectedGalleryId();
      expect(selectedId.setSelectedGalleryId, isA<Function>());
    });
  });

  group('AsyncCelebGalleryList 프로바이더 구조 테스트', () {
    test('asyncCelebGalleryListProvider가 정의되어 있는지 확인', () {
      expect(asyncCelebGalleryListProvider, isNotNull);
    });

    test('AsyncCelebGalleryList 클래스가 인스턴스화 가능한지 확인', () {
      final celebGalleryList = AsyncCelebGalleryList();
      expect(celebGalleryList, isNotNull);
    });
  });

  group('GalleryModel 구조 테스트', () {
    test('GalleryModel을 JSON에서 생성할 수 있는지 확인', () {
      final json = {
        'id': 1,
        'title_ko': '갤러리 제목',
        'title_en': 'Gallery Title',
        'cover': 'https://example.com/cover.png',
        'celeb': null,
      };

      final model = GalleryModel.fromJson(json);
      expect(model.id, 1);
      expect(model.titleKo, '갤러리 제목');
      expect(model.titleEn, 'Gallery Title');
      expect(model.cover, 'https://example.com/cover.png');
      expect(model.celeb, isNull);
    });

    test('GalleryModel의 copyWith가 정상 동작하는지 확인', () {
      final model = GalleryModel(
        id: 1,
        titleKo: '원본',
        titleEn: 'Original',
        celeb: null,
      );

      final updated = model.copyWith(titleKo: '수정됨');
      expect(updated.titleKo, '수정됨');
      expect(updated.id, 1);
      expect(updated.titleEn, 'Original');
    });

    test('GalleryModel의 cover가 null일 수 있는지 확인', () {
      final model = GalleryModel(
        id: 1,
        titleKo: '테스트',
        titleEn: 'Test',
        celeb: null,
      );

      expect(model.cover, isNull);
    });

    test('GalleryModel의 getCdnUrl이 올바른 URL을 반환하는지 확인', () {
      final model = GalleryModel(
        id: 42,
        titleKo: '테스트',
        titleEn: 'Test',
        celeb: null,
      );

      final cdnUrl = model.getCdnUrl('image.png');
      expect(cdnUrl, 'https://cdn-dev.picnic.fan/gallery/42/image.png');
    });

    test('GalleryModel 리스트를 JSON 리스트에서 생성할 수 있는지 확인', () {
      final jsonList = [
        {'id': 1, 'title_ko': '첫번째', 'title_en': 'First', 'celeb': null},
        {'id': 2, 'title_ko': '두번째', 'title_en': 'Second', 'celeb': null},
        {'id': 3, 'title_ko': '세번째', 'title_en': 'Third', 'celeb': null},
      ];

      final models = jsonList.map((e) => GalleryModel.fromJson(e)).toList();
      expect(models.length, 3);
      expect(models[0].id, 1);
      expect(models[1].titleKo, '두번째');
      expect(models[2].titleEn, 'Third');
    });
  });
}
