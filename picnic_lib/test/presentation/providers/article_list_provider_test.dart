import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/providers/article_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('fetchArticleList provider with mock Supabase', () {
    setUp(() {
      setupMockSupabase({
        'article': [
          {
            'id': 1,
            'title_ko': '첫 번째 기사',
            'title_en': 'First Article',
            'content': 'Content 1',
            'gallery': null,
            'article_image': [
              {
                'id': 10,
                'title_ko': '이미지1',
                'title_en': 'Image1',
                'image': 'img1.jpg',
                'article_image_user': null,
              }
            ],
            'created_at': '2024-01-01T00:00:00.000Z',
            'comment_count': 5,
            'comment': null,
            'most_liked_comment': null,
          },
          {
            'id': 2,
            'title_ko': '두 번째 기사',
            'title_en': 'Second Article',
            'content': 'Content 2',
            'gallery': null,
            'article_image': null,
            'created_at': '2024-01-02T00:00:00.000Z',
            'comment_count': 0,
            'comment': null,
            'most_liked_comment': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of ArticleModel from mock data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        fetchArticleListProvider(
          page: 1,
          galleryId: 1,
          limit: 10,
          sort: 'id',
          order: 'DESC',
        ).future,
      );

      expect(result, isA<List<ArticleModel>>());
      expect(result!.length, 2);
    });

    test('data matches expected model fields', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        fetchArticleListProvider(
          page: 1,
          galleryId: 1,
          limit: 10,
          sort: 'id',
          order: 'DESC',
        ).future,
      );

      final first = result![0];
      expect(first.id, 1);
      expect(first.titleKo, '첫 번째 기사');
      expect(first.titleEn, 'First Article');
      expect(first.content, 'Content 1');
      expect(first.commentCount, 5);
      expect(first.articleImage, isNotNull);
      expect(first.articleImage!.length, 1);
      expect(first.gallery, isNull);
      expect(first.comment, isNull);

      final second = result[1];
      expect(second.id, 2);
      expect(second.titleKo, '두 번째 기사');
      expect(second.articleImage, isNull);
      expect(second.commentCount, 0);
    });
  });

  group('fetchArticleList provider with empty data', () {
    setUp(() {
      setupMockSupabase({
        'article': [],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty list when no articles', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        fetchArticleListProvider(
          page: 1,
          galleryId: 1,
          limit: 10,
          sort: 'id',
          order: 'DESC',
        ).future,
      );

      expect(result, isA<List<ArticleModel>>());
      expect(result, isEmpty);
    });
  });

  group('fetchArticleList provider with different parameters', () {
    setUp(() {
      setupMockSupabase({
        'article': [
          {
            'id': 5,
            'title_ko': '기사',
            'title_en': 'Article',
            'content': 'Test content',
            'gallery': null,
            'article_image': null,
            'created_at': '2024-06-01T12:00:00.000Z',
            'comment_count': null,
            'comment': null,
            'most_liked_comment': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('ascending order parameter works', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        fetchArticleListProvider(
          page: 1,
          galleryId: 2,
          limit: 5,
          sort: 'created_at',
          order: 'ASC',
        ).future,
      );

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].id, 5);
    });

    test('different page and limit values work', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        fetchArticleListProvider(
          page: 2,
          galleryId: 1,
          limit: 20,
          sort: 'id',
          order: 'DESC',
        ).future,
      );

      // Mock returns all data regardless of range, but provider should not crash
      expect(result, isNotNull);
    });
  });

  group('SortOption provider', () {
    test('initial value has sort=id and order=DESC', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(sortOptionProvider);
      expect(result.sort, 'id');
      expect(result.order, 'DESC');
    });

    test('setSortOption updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(sortOptionProvider.notifier)
          .setSortOption('created_at', 'ASC');
      final result = container.read(sortOptionProvider);

      expect(result.sort, 'created_at');
      expect(result.order, 'ASC');
    });

    test('setSortOption can be called multiple times', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(sortOptionProvider.notifier)
          .setSortOption('created_at', 'ASC');
      container
          .read(sortOptionProvider.notifier)
          .setSortOption('comment_count', 'DESC');

      final result = container.read(sortOptionProvider);
      expect(result.sort, 'comment_count');
      expect(result.order, 'DESC');
    });
  });

  group('CommentCount provider', () {
    test('initial value is 0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(commentCountProvider(1).future);
      expect(result, 0);
    });

    test('setCount updates value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initial build
      await container.read(commentCountProvider(1).future);

      container.read(commentCountProvider(1).notifier).setCount(10);
      final result = await container.read(commentCountProvider(1).future);
      expect(result, 10);
    });

    test('increment increases value by 1', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(commentCountProvider(1).future);

      container.read(commentCountProvider(1).notifier).setCount(5);
      container.read(commentCountProvider(1).notifier).increment();

      final result = await container.read(commentCountProvider(1).future);
      expect(result, 6);
    });

    test('decrement decreases value by 1', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(commentCountProvider(1).future);

      container.read(commentCountProvider(1).notifier).setCount(5);
      container.read(commentCountProvider(1).notifier).decrement();

      final result = await container.read(commentCountProvider(1).future);
      expect(result, 4);
    });

    test('different articleIds have separate states', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(commentCountProvider(1).future);
      await container.read(commentCountProvider(2).future);

      container.read(commentCountProvider(1).notifier).setCount(10);
      container.read(commentCountProvider(2).notifier).setCount(20);

      final result1 = await container.read(commentCountProvider(1).future);
      final result2 = await container.read(commentCountProvider(2).future);

      expect(result1, 10);
      expect(result2, 20);
    });
  });

  group('ArticleModel structure tests', () {
    test('ArticleModel fromJson with all fields', () {
      final json = {
        'id': 1,
        'title_ko': '제목',
        'title_en': 'Title',
        'content': '본문',
        'gallery': null,
        'article_image': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'comment_count': 3,
        'comment': null,
        'most_liked_comment': null,
      };

      final model = ArticleModel.fromJson(json);
      expect(model.id, 1);
      expect(model.titleKo, '제목');
      expect(model.titleEn, 'Title');
      expect(model.content, '본문');
      expect(model.commentCount, 3);
      expect(model.gallery, isNull);
      expect(model.articleImage, isNull);
    });

    test('ArticleModel copyWith works correctly', () {
      final model = ArticleModel(
        id: 1,
        titleKo: '원본',
        titleEn: 'Original',
        content: 'content',
        gallery: null,
        articleImage: null,
        createdAt: DateTime(2024, 1, 1),
        commentCount: 0,
        comment: null,
        mostLikedComment: null,
      );

      final updated = model.copyWith(titleKo: '수정됨', commentCount: 10);
      expect(updated.titleKo, '수정됨');
      expect(updated.commentCount, 10);
      expect(updated.id, 1);
      expect(updated.titleEn, 'Original');
    });
  });
}
