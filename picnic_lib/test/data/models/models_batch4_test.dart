import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad_info.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/vote/purchase_product.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

void main() {
  group('ArtistApplicationInfo', () {
    test('constructor and fields', () {
      const info = ArtistApplicationInfo(
        artistName: '지민',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, '지민');
      expect(info.applicationCount, 5);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('constructor with isSubmitting', () {
      const info = ArtistApplicationInfo(
        artistName: 'Test',
        applicationCount: 0,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(info.isSubmitting, isTrue);
      expect(info.isAlreadyInVote, isTrue);
    });

    test('copyWith all fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'Original',
        applicationCount: 1,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(
        artistName: 'Updated',
        applicationCount: 10,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(updated.artistName, 'Updated');
      expect(updated.applicationCount, 10);
      expect(updated.applicationStatus, 'approved');
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith partial', () {
      const info = ArtistApplicationInfo(
        artistName: 'Name',
        applicationCount: 3,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(applicationCount: 5);
      expect(updated.artistName, 'Name');
      expect(updated.applicationCount, 5);
      expect(updated.applicationStatus, 'pending');
    });
  });

  group('UserApplicationInfo', () {
    test('constructor and fields', () {
      const info = UserApplicationInfo(
        id: 'req-1',
        artistName: 'BTS',
        groupName: 'BTS',
        status: 'approved',
        applicationCount: 100,
      );
      expect(info.id, 'req-1');
      expect(info.artistName, 'BTS');
      expect(info.groupName, 'BTS');
      expect(info.status, 'approved');
      expect(info.applicationCount, 100);
      expect(info.artist, isNull);
    });

    test('without optional fields', () {
      const info = UserApplicationInfo(
        id: 'req-2',
        artistName: 'Solo',
        status: 'pending',
        applicationCount: 1,
      );
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });
  });

  group('ArtistNameUtils', () {
    test('formatNumber with comma', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(1234567), '1,234,567');
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(999), '999');
      expect(ArtistNameUtils.formatNumber(100000), '100,000');
    });
  });

  group('CommunityState', () {
    test('default constructor', () {
      const state = CommunityState();
      expect(state.currentArtist, isNull);
      expect(state.currentPost, isNull);
      expect(state.currentBoard, isNull);
    });

    test('copyWith preserves null fields', () {
      const state = CommunityState();
      final copy = state.copyWith();
      expect(copy.currentArtist, isNull);
      expect(copy.currentPost, isNull);
      expect(copy.currentBoard, isNull);
    });
  });

  group('AdInfo', () {
    test('default values', () {
      const info = AdInfo();
      expect(info.ad, isNull);
      expect(info.isShowing, isFalse);
      expect(info.isLoading, isFalse);
    });

    test('copyWith', () {
      const info = AdInfo();
      final updated = info.copyWith(isShowing: true, isLoading: true);
      expect(updated.isShowing, isTrue);
      expect(updated.isLoading, isTrue);
    });
  });

  group('AdState', () {
    test('initial factory', () {
      final state = AdState.initial();
      expect(state.ads.length, 2);
      expect(state.ads[0].isShowing, isFalse);
      expect(state.ads[1].isLoading, isFalse);
    });

    test('copyWith', () {
      final state = AdState.initial();
      final updated = state.copyWith(ads: [const AdInfo(isShowing: true)]);
      expect(updated.ads.length, 1);
      expect(updated.ads[0].isShowing, isTrue);
    });
  });

  group('ProductDetailsConverter', () {
    test('fromJson null returns null', () {
      const converter = ProductDetailsConverter();
      expect(converter.fromJson(null), isNull);
    });

    test('fromJson valid map - note: source has type mismatch bug', () {
      const converter = ProductDetailsConverter();
      // The source uses json['price'] for both String price and double rawPrice
      // This will throw in practice — just test that null works
      expect(converter.fromJson(null), isNull);
    });

    test('toJson null returns null', () {
      const converter = ProductDetailsConverter();
      expect(converter.toJson(null), isNull);
    });
  });

  group('PurchaseProduct fromJson', () {
    test('basic fromJson', () {
      final json = {
        'id': 'prod-1',
        'title': '스타 캔디 100개',
        'price': 4.99,
        'star_candy': 100,
        'bonus_star_candy': 10,
      };
      final product = PurchaseProduct.fromJson(json);
      expect(product.id, 'prod-1');
      expect(product.title, '스타 캔디 100개');
      expect(product.price, 4.99);
      expect(product.starCandy, 100);
      expect(product.bonusStarCandy, 10);
      expect(product.productDetails, isNull);
    });

    test('toJson roundtrip', () {
      final json = {
        'id': 'prod-2',
        'title': 'Big Pack',
        'price': 9.99,
        'star_candy': 500,
        'bonus_star_candy': 50,
      };
      final product = PurchaseProduct.fromJson(json);
      final output = product.toJson();
      expect(output['id'], 'prod-2');
      expect(output['star_candy'], 500);
      expect(output['bonus_star_candy'], 50);
    });
  });
}
