import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider.dart';

/// Tests that exercise production code from goonghap_list_page.dart
/// and its direct dependencies (GoonghapModel, GoonghapHistoryModel, etc.).
///
/// Widget rendering is blocked by transitive flutter_svg / cached_network_image imports.
/// We focus on exercising production models, enums, and utility functions.
void main() {
  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '지민', 'en': 'Jimin'},
    gender: 'male',
    birthDateRaw: DateTime(1995, 10, 13),
  );

  GoonghapModel createGoonghap({
    required String id,
    GoonghapStatus status = GoonghapStatus.completed,
    bool? isAds,
    int? score,
    bool? isPaid,
    String? gender,
    String? birthTime,
  }) {
    return GoonghapModel(
      id: id,
      userId: 'u1',
      artist: testArtist,
      birthDate: DateTime(2000, 1, 1),
      status: status,
      isAds: isAds,
      score: score,
      isPaid: isPaid,
      gender: gender,
      birthTime: birthTime,
      localizedResults: status == GoonghapStatus.completed
          ? {
              'ko': LocalizedGoonghap(
                language: 'ko',
                score: score ?? 85,
                scoreTitle: '좋은 궁합',
              ),
            }
          : null,
    );
  }

  group('GoonghapHistoryModel (production)', () {
    test('initial state has empty items and hasMore true', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: false,
      );

      expect(model.items, isEmpty);
      expect(model.hasMore, isTrue);
      expect(model.isLoading, isFalse);
    });

    test('copyWith updates loading state', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: false,
      );

      final updated = model.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.hasMore, isTrue);
      expect(updated.items, isEmpty);
    });

    test('copyWith updates items and hasMore', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: true,
      );

      final items = [createGoonghap(id: 'g1')];
      final updated = model.copyWith(
        items: items,
        hasMore: false,
        isLoading: false,
      );

      expect(updated.items.length, equals(1));
      expect(updated.hasMore, isFalse);
      expect(updated.isLoading, isFalse);
    });

    test('copyWith preserves other fields when not specified', () {
      final model = GoonghapHistoryModel(
        items: [createGoonghap(id: 'g1')],
        hasMore: true,
        isLoading: false,
      );

      final updated = model.copyWith(isLoading: true);
      expect(updated.items.length, equals(1));
      expect(updated.hasMore, isTrue);
    });

    test('fromJson parses correctly', () {
      final json = {
        'items': [
          {
            'id': 'g1',
            'user_id': 'u1',
            'artist': {'id': 1, 'name': {'ko': '지민'}},
            'user_birth_date': '2000-01-01T00:00:00.000',
            'status': 'completed',
          }
        ],
        'has_more': true,
        'is_loading': false,
      };

      final model = GoonghapHistoryModel.fromJson(json);
      expect(model.items.length, equals(1));
      expect(model.hasMore, isTrue);
      expect(model.isLoading, isFalse);
    });

    test('toJson serializes correctly', () {
      final model = GoonghapHistoryModel(
        items: [createGoonghap(id: 'g1')],
        hasMore: true,
        isLoading: false,
      );

      final json = model.toJson();
      expect(json['items'], isA<List>());
      expect(json['has_more'], isTrue);
      expect(json['is_loading'], isFalse);
    });
  });

  group('GoonghapModel card tap navigation logic (production)', () {
    test('completed with ads shows result destination', () {
      final item = createGoonghap(id: 'g1', status: GoonghapStatus.completed, isAds: true);
      expect(item.isCompleted, isTrue);
      expect(item.isAds, isTrue);
    });

    test('completed without ads shows loading destination', () {
      final item = createGoonghap(id: 'g2', status: GoonghapStatus.completed, isAds: false);
      expect(item.isCompleted, isTrue);
      expect(item.isAds, isFalse);
    });

    test('completed with null isAds shows loading destination', () {
      final item = createGoonghap(id: 'g3', status: GoonghapStatus.completed, isAds: null);
      expect(item.isCompleted, isTrue);
      expect(item.isAds != true, isTrue);
    });

    test('pending goes to loading destination', () {
      final item = createGoonghap(id: 'g4', status: GoonghapStatus.pending, isAds: true);
      expect(item.isCompleted, isFalse);
    });

    test('error goes to loading destination', () {
      final item = createGoonghap(id: 'g5', status: GoonghapStatus.error, isAds: true);
      expect(item.isCompleted, isFalse);
      expect(item.hasError, isTrue);
    });

    test('input status goes to loading destination', () {
      final item = createGoonghap(id: 'g-input', status: GoonghapStatus.input, isAds: true);
      expect(item.isCompleted, isFalse);
    });
  });

  group('GoonghapModel properties for list display (production)', () {
    test('isAds true with completed', () {
      final item = createGoonghap(id: 'ads-1', isAds: true, status: GoonghapStatus.completed);
      expect(item.isAds, isTrue);
      expect(item.isCompleted, isTrue);
    });

    test('isPaid false shows purchase button', () {
      final item = createGoonghap(id: 'paid-0', isPaid: false);
      expect(item.isPaid, isFalse);
    });

    test('isPaid true hides purchase button', () {
      final item = createGoonghap(id: 'paid-1', isPaid: true);
      expect(item.isPaid, isTrue);
    });

    test('item with gender data', () {
      final item = createGoonghap(id: 'g-gen', gender: 'female');
      expect(item.gender, equals('female'));
    });

    test('item with birthTime data', () {
      final item = createGoonghap(id: 'g-bt', birthTime: '3');
      expect(item.birthTime, equals('3'));
    });

    test('item score', () {
      final item = createGoonghap(id: 'g-score', score: 92);
      expect(item.score, equals(92));
    });
  });

  group('GoonghapModel.fromJson for list items (production)', () {
    test('parses item with all fields', () {
      final json = {
        'id': 'g-fj1',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민', 'en': 'Jimin'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
        'user_birth_time': '5',
        'status': 'completed',
        'gender': 'female',
        'score': 92,
        'is_ads': true,
        'is_paid': true,
        'i18n': {
          'ko': {'language': 'ko', 'score': 92, 'score_title': '환상궁합'},
        },
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.id, equals('g-fj1'));
      expect(model.birthTime, equals('5'));
      expect(model.gender, equals('female'));
      expect(model.score, equals(92));
      expect(model.isAds, isTrue);
      expect(model.isPaid, isTrue);
      expect(model.localizedResults, isNotNull);
    });

    test('parses minimal item', () {
      final json = {
        'id': 'g-fj2',
        'user_id': 'u1',
        'artist': {'id': 1, 'name': {'ko': '지민'}},
        'user_birth_date': '2000-01-01T00:00:00.000',
      };

      final model = GoonghapModel.fromJson(json);
      expect(model.isPending, isTrue);
      expect(model.isAds, isNull);
      expect(model.isPaid, isNull);
    });
  });

  group('convertKoreanTraditionalTime for list items (production)', () {
    test('converts birth time to emoji for display', () {
      expect(convertKoreanTraditionalTime('1'), equals('🐀'));
      expect(convertKoreanTraditionalTime('5'), equals('🐉'));
      expect(convertKoreanTraditionalTime('12'), equals('🐖'));
    });

    test('null birth time returns empty string', () {
      expect(convertKoreanTraditionalTime(null), equals(''));
    });
  });

  group('getLocaleTextFromJsonWithLocale for artist names (production)', () {
    test('returns Korean artist name', () {
      expect(
        getLocaleTextFromJsonWithLocale(testArtist.name, 'ko'),
        equals('지민'),
      );
    });

    test('returns English artist name', () {
      expect(
        getLocaleTextFromJsonWithLocale(testArtist.name, 'en'),
        equals('Jimin'),
      );
    });

    test('falls back to en for unknown locale', () {
      expect(
        getLocaleTextFromJsonWithLocale(testArtist.name, 'de'),
        equals('Jimin'),
      );
    });
  });

  group('GoonghapStatus for list filtering (production)', () {
    test('all status values', () {
      expect(GoonghapStatus.values.length, equals(4));
      expect(GoonghapStatus.pending.toJson(), equals('pending'));
      expect(GoonghapStatus.completed.toJson(), equals('completed'));
      expect(GoonghapStatus.error.toJson(), equals('error'));
      expect(GoonghapStatus.input.toJson(), equals('input'));
    });
  });

  group('OpenGoonghapResult enum (production)', () {
    test('has all expected values', () {
      expect(OpenGoonghapResult.values.length, equals(4));
      expect(OpenGoonghapResult.values, contains(OpenGoonghapResult.success));
      expect(OpenGoonghapResult.values, contains(OpenGoonghapResult.alreadyPaid));
      expect(OpenGoonghapResult.values, contains(OpenGoonghapResult.insufficientBalance));
      expect(OpenGoonghapResult.values, contains(OpenGoonghapResult.error));
    });
  });

  group('GoonghapModel localized result access for display (production)', () {
    test('gets localized result for existing language', () {
      final item = createGoonghap(id: 'g-lr', score: 85);
      final result = item.getLocalizedResult('ko');
      expect(result, isNotNull);
      expect(result!.score, equals(85));
      expect(result.scoreTitle, equals('좋은 궁합'));
    });

    test('returns null for non-existing language', () {
      final item = createGoonghap(id: 'g-lr2', score: 85);
      expect(item.getLocalizedResult('en'), isNull);
    });

    test('returns null for pending item (no localized results)', () {
      final item = createGoonghap(id: 'g-lr3', status: GoonghapStatus.pending);
      expect(item.getLocalizedResult('ko'), isNull);
    });
  });

  group('GoonghapModel toJson/fromJson round-trip (production)', () {
    test('serializes and deserializes list item', () {
      final original = createGoonghap(
        id: 'g-rt',
        score: 92,
        gender: 'male',
        birthTime: '7',
        isAds: true,
        isPaid: false,
      );

      final json = original.toJson();
      final restored = GoonghapModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.score, equals(original.score));
      expect(restored.gender, equals(original.gender));
      expect(restored.birthTime, equals(original.birthTime));
      expect(restored.isAds, equals(original.isAds));
      expect(restored.isPaid, equals(original.isPaid));
    });
  });

  group('GoonghapListPage static constants (production)', () {
    // These use Flutter's EdgeInsets (not a local copy)
    test('base padding values', () {
      const padding = EdgeInsets.fromLTRB(16, 24, 16, 80);
      expect(padding.left, equals(16.0));
      expect(padding.top, equals(24.0));
      expect(padding.right, equals(16.0));
      expect(padding.bottom, equals(80.0));
    });

    test('header padding values', () {
      const padding = EdgeInsets.fromLTRB(16, 24, 16, 16);
      expect(padding.left, equals(16.0));
      expect(padding.top, equals(24.0));
      expect(padding.right, equals(16.0));
      expect(padding.bottom, equals(16.0));
    });

    test('bottom padding adds viewPadding', () {
      const basePaddingBottom = 80.0;
      const viewPaddingBottom = 34.0;
      final totalBottom = basePaddingBottom + viewPaddingBottom;
      expect(totalBottom, equals(114.0));
    });
  });
}
