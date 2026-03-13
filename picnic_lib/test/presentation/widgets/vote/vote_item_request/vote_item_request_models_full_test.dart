import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('ArtistApplicationInfo', () {
    test('constructor sets all fields', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, 'BTS');
      expect(info.applicationCount, 5);
      expect(info.applicationStatus, 'pending');
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('isSubmitting defaults to false', () {
      const info = ArtistApplicationInfo(
        artistName: 'IU',
        applicationCount: 0,
        applicationStatus: 'open',
        isAlreadyInVote: false,
      );
      expect(info.isSubmitting, isFalse);
    });

    test('copyWith updates selected fields', () {
      const original = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );

      final copied = original.copyWith(applicationCount: 10, isSubmitting: true);
      expect(copied.artistName, 'BTS');
      expect(copied.applicationCount, 10);
      expect(copied.applicationStatus, 'pending');
      expect(copied.isAlreadyInVote, isFalse);
      expect(copied.isSubmitting, isTrue);
    });

    test('copyWith with no args returns equivalent object', () {
      const original = ArtistApplicationInfo(
        artistName: 'NewJeans',
        applicationCount: 3,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );

      final copied = original.copyWith();
      expect(copied.artistName, original.artistName);
      expect(copied.applicationCount, original.applicationCount);
      expect(copied.applicationStatus, original.applicationStatus);
      expect(copied.isAlreadyInVote, original.isAlreadyInVote);
      expect(copied.isSubmitting, original.isSubmitting);
    });

    test('copyWith updates all fields', () {
      const original = ArtistApplicationInfo(
        artistName: 'A',
        applicationCount: 0,
        applicationStatus: 'open',
        isAlreadyInVote: false,
      );

      final copied = original.copyWith(
        artistName: 'B',
        applicationCount: 99,
        applicationStatus: 'closed',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(copied.artistName, 'B');
      expect(copied.applicationCount, 99);
      expect(copied.applicationStatus, 'closed');
      expect(copied.isAlreadyInVote, isTrue);
      expect(copied.isSubmitting, isTrue);
    });
  });

  group('UserApplicationInfo', () {
    test('constructor sets required fields', () {
      const info = UserApplicationInfo(
        id: '1',
        artistName: 'IU',
        status: 'approved',
        applicationCount: 3,
      );
      expect(info.id, '1');
      expect(info.artistName, 'IU');
      expect(info.status, 'approved');
      expect(info.applicationCount, 3);
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('constructor sets optional fields', () {
      const info = UserApplicationInfo(
        id: '2',
        artistName: 'Jimin',
        groupName: 'BTS',
        status: 'pending',
        applicationCount: 1,
      );
      expect(info.groupName, 'BTS');
    });
  });

  group('VoteRequestStatusUtils.getStatusColor', () {
    test('pending returns orange', () {
      expect(VoteRequestStatusUtils.getStatusColor('pending'), Colors.orange);
    });

    test('approved returns green', () {
      expect(VoteRequestStatusUtils.getStatusColor('approved'), Colors.green);
    });

    test('rejected returns red', () {
      expect(VoteRequestStatusUtils.getStatusColor('rejected'), Colors.red);
    });

    test('in-progress returns primary color', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('in-progress'),
        AppColors.primary500,
      );
    });

    test('cancelled returns grey', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('cancelled'),
        AppColors.grey400,
      );
    });

    test('unknown returns grey', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('unknown'),
        AppColors.grey400,
      );
    });

    test('case insensitive', () {
      expect(VoteRequestStatusUtils.getStatusColor('PENDING'), Colors.orange);
      expect(VoteRequestStatusUtils.getStatusColor('Approved'), Colors.green);
      expect(VoteRequestStatusUtils.getStatusColor('REJECTED'), Colors.red);
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('formats small numbers', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('formats thousands with comma', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
      expect(ArtistNameUtils.formatNumber(9999), '9,999');
    });

    test('formats millions with commas', () {
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
    });

    test('formats large numbers', () {
      expect(ArtistNameUtils.formatNumber(1234567890), '1,234,567,890');
    });
  });
}
