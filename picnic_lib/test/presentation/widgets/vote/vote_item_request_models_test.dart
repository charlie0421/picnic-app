import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });
  group('ArtistApplicationInfo', () {
    test('constructor sets all fields', () {
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
      expect(info.isSubmitting, isFalse); // default
    });

    test('copyWith updates fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      final updated = info.copyWith(
        artistName: 'BLACKPINK',
        applicationCount: 200,
        isSubmitting: true,
      );

      expect(updated.artistName, 'BLACKPINK');
      expect(updated.applicationCount, 200);
      expect(updated.applicationStatus, 'pending'); // preserved
      expect(updated.isAlreadyInVote, isFalse); // preserved
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith preserves all unchanged fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );

      final updated = info.copyWith(applicationCount: 150);

      expect(updated.artistName, 'BTS');
      expect(updated.applicationCount, 150);
      expect(updated.applicationStatus, 'approved');
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });
  });

  group('UserApplicationInfo', () {
    test('constructor sets all fields', () {
      const info = UserApplicationInfo(
        id: 'app-1',
        artistName: 'TWICE',
        groupName: 'JYP',
        status: 'pending',
        applicationCount: 50,
      );

      expect(info.id, 'app-1');
      expect(info.artistName, 'TWICE');
      expect(info.groupName, 'JYP');
      expect(info.status, 'pending');
      expect(info.applicationCount, 50);
      expect(info.artist, isNull);
    });

    test('optional fields can be null', () {
      const info = UserApplicationInfo(
        id: 'app-2',
        artistName: 'IVE',
        status: 'approved',
        applicationCount: 30,
      );

      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });
  });

  group('ArtistNameUtils', () {
    test('formatNumber adds commas for thousands', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
      expect(ArtistNameUtils.formatNumber(1234567), '1,234,567');
    });

    test('formatNumber does not add commas for small numbers', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(1), '1');
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('formatNumber handles edge cases', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(10000), '10,000');
      expect(ArtistNameUtils.formatNumber(100000), '100,000');
    });
  });

  group('VoteRequestStatusUtils', () {
    test('getStatusColor returns correct colors for each status', () {
      expect(VoteRequestStatusUtils.getStatusColor('pending').value,
          isNot(equals(0)));
      expect(VoteRequestStatusUtils.getStatusColor('approved').value,
          isNot(equals(0)));
      expect(VoteRequestStatusUtils.getStatusColor('rejected').value,
          isNot(equals(0)));
      expect(VoteRequestStatusUtils.getStatusColor('in-progress').value,
          isNot(equals(0)));
      expect(VoteRequestStatusUtils.getStatusColor('cancelled').value,
          isNot(equals(0)));
      expect(VoteRequestStatusUtils.getStatusColor('unknown').value,
          isNot(equals(0)));
    });

    test('getStatusColor is case insensitive', () {
      expect(VoteRequestStatusUtils.getStatusColor('PENDING'),
          equals(VoteRequestStatusUtils.getStatusColor('pending')));
      expect(VoteRequestStatusUtils.getStatusColor('Approved'),
          equals(VoteRequestStatusUtils.getStatusColor('approved')));
    });
  });
}
