import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());

  group('ArtistApplicationInfo', () {
    test('기본 생성', () {
      const info = ArtistApplicationInfo(
        artistName: '정국',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, equals('정국'));
      expect(info.applicationCount, equals(5));
      expect(info.applicationStatus, equals('pending'));
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('copyWith 동작', () {
      const info = ArtistApplicationInfo(
        artistName: '정국',
        applicationCount: 5,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(
        applicationCount: 10,
        isSubmitting: true,
      );
      expect(updated.artistName, equals('정국'));
      expect(updated.applicationCount, equals(10));
      expect(updated.isSubmitting, isTrue);
      expect(updated.applicationStatus, equals('pending'));
    });

    test('copyWith 모든 필드 변경', () {
      const info = ArtistApplicationInfo(
        artistName: '뷔',
        applicationCount: 3,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(
        artistName: '진',
        applicationCount: 7,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(updated.artistName, equals('진'));
      expect(updated.applicationCount, equals(7));
      expect(updated.applicationStatus, equals('approved'));
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });
  });

  group('UserApplicationInfo', () {
    test('기본 생성', () {
      const info = UserApplicationInfo(
        id: 'req-1',
        artistName: '카리나',
        status: 'pending',
        applicationCount: 3,
      );
      expect(info.id, equals('req-1'));
      expect(info.artistName, equals('카리나'));
      expect(info.groupName, isNull);
      expect(info.status, equals('pending'));
      expect(info.applicationCount, equals(3));
      expect(info.artist, isNull);
    });

    test('그룹 이름 포함', () {
      const info = UserApplicationInfo(
        id: 'req-2',
        artistName: '윈터',
        groupName: 'aespa',
        status: 'approved',
        applicationCount: 10,
      );
      expect(info.groupName, equals('aespa'));
    });
  });

  group('VoteRequestStatusUtils.getStatusColor', () {
    test('pending은 오렌지', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('pending'),
        equals(Colors.orange),
      );
    });

    test('approved은 그린', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('approved'),
        equals(Colors.green),
      );
    });

    test('rejected은 레드', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('rejected'),
        equals(Colors.red),
      );
    });

    test('in-progress는 primary500', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('in-progress'),
        equals(AppColors.primary500),
      );
    });

    test('cancelled은 grey400', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('cancelled'),
        equals(AppColors.grey400),
      );
    });

    test('알 수 없는 상태는 grey400', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('unknown'),
        equals(AppColors.grey400),
      );
    });

    test('대소문자 무시', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('PENDING'),
        equals(Colors.orange),
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('Approved'),
        equals(Colors.green),
      );
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('천 단위 콤마', () {
      expect(ArtistNameUtils.formatNumber(1000), equals('1,000'));
    });

    test('만 단위', () {
      expect(ArtistNameUtils.formatNumber(10000), equals('10,000'));
    });

    test('백만 단위', () {
      expect(ArtistNameUtils.formatNumber(1000000), equals('1,000,000'));
    });

    test('천 미만은 콤마 없음', () {
      expect(ArtistNameUtils.formatNumber(999), equals('999'));
    });

    test('0', () {
      expect(ArtistNameUtils.formatNumber(0), equals('0'));
    });

    test('1자리', () {
      expect(ArtistNameUtils.formatNumber(5), equals('5'));
    });

    test('큰 숫자', () {
      expect(
        ArtistNameUtils.formatNumber(1234567890),
        equals('1,234,567,890'),
      );
    });
  });
}
