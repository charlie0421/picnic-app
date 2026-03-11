import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

void main() {
  group('ArtistApplicationInfo', () {
    test('creates with required fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, 'BTS');
      expect(info.applicationCount, 100);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('creates with isSubmitting true', () {
      const info = ArtistApplicationInfo(
        artistName: 'BLACKPINK',
        applicationCount: 50,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(info.isSubmitting, isTrue);
      expect(info.isAlreadyInVote, isTrue);
    });

    test('copyWith updates artistName', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(artistName: 'NewJeans');
      expect(updated.artistName, 'NewJeans');
      expect(updated.applicationCount, 100);
    });

    test('copyWith updates applicationCount', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(applicationCount: 200);
      expect(updated.applicationCount, 200);
      expect(updated.artistName, 'BTS');
    });

    test('copyWith updates isSubmitting', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(isSubmitting: true);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'TWICE',
        applicationCount: 75,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      final updated = info.copyWith(applicationStatus: 'rejected');
      expect(updated.artistName, 'TWICE');
      expect(updated.applicationCount, 75);
      expect(updated.applicationStatus, 'rejected');
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });
  });

  group('UserApplicationInfo', () {
    test('creates with required fields', () {
      const info = UserApplicationInfo(
        id: 'app-1',
        artistName: 'BTS',
        status: 'pending',
        applicationCount: 10,
      );
      expect(info.id, 'app-1');
      expect(info.artistName, 'BTS');
      expect(info.status, 'pending');
      expect(info.applicationCount, 10);
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('creates with optional groupName', () {
      const info = UserApplicationInfo(
        id: 'app-2',
        artistName: 'Jungkook',
        groupName: 'BTS',
        status: 'approved',
        applicationCount: 50,
      );
      expect(info.groupName, 'BTS');
    });
  });

  group('ArtistNameUtils', () {
    test('formatNumber formats with commas', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
      expect(ArtistNameUtils.formatNumber(999), '999');
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(12345678), '12,345,678');
    });

    test('formatNumber handles small numbers', () {
      expect(ArtistNameUtils.formatNumber(1), '1');
      expect(ArtistNameUtils.formatNumber(99), '99');
      expect(ArtistNameUtils.formatNumber(100), '100');
    });
  });
}
