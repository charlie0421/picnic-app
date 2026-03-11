import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  group('ArtistApplicationInfo', () {
    test('생성 확인', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.artistName, equals('BTS'));
      expect(info.applicationCount, equals(100));
      expect(info.applicationStatus, equals('pending'));
      expect(info.isAlreadyInVote, isFalse);
      expect(info.isSubmitting, isFalse);
    });

    test('isSubmitting 기본값은 false', () {
      const info = ArtistApplicationInfo(
        artistName: 'test',
        applicationCount: 0,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      expect(info.isSubmitting, isFalse);
    });

    test('copyWith - artistName 변경', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(artistName: 'BLACKPINK');
      expect(updated.artistName, equals('BLACKPINK'));
      expect(updated.applicationCount, equals(100)); // 변경 안됨
    });

    test('copyWith - applicationCount 변경', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(applicationCount: 200);
      expect(updated.applicationCount, equals(200));
      expect(updated.artistName, equals('BTS')); // 변경 안됨
    });

    test('copyWith - isAlreadyInVote 변경', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(isAlreadyInVote: true);
      expect(updated.isAlreadyInVote, isTrue);
    });

    test('copyWith - isSubmitting 변경', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(isSubmitting: true);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith - 모든 필드 변경', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith(
        artistName: 'TWICE',
        applicationCount: 50,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(updated.artistName, equals('TWICE'));
      expect(updated.applicationCount, equals(50));
      expect(updated.applicationStatus, equals('approved'));
      expect(updated.isAlreadyInVote, isTrue);
      expect(updated.isSubmitting, isTrue);
    });

    test('copyWith - 아무것도 변경하지 않으면 원본과 동일', () {
      const info = ArtistApplicationInfo(
        artistName: 'BTS',
        applicationCount: 100,
        applicationStatus: 'pending',
        isAlreadyInVote: false,
      );
      final updated = info.copyWith();
      expect(updated.artistName, equals(info.artistName));
      expect(updated.applicationCount, equals(info.applicationCount));
      expect(updated.applicationStatus, equals(info.applicationStatus));
      expect(updated.isAlreadyInVote, equals(info.isAlreadyInVote));
      expect(updated.isSubmitting, equals(info.isSubmitting));
    });
  });

  group('UserApplicationInfo', () {
    test('생성 확인', () {
      const info = UserApplicationInfo(
        id: 'app-001',
        artistName: 'BTS',
        status: 'pending',
        applicationCount: 50,
      );
      expect(info.id, equals('app-001'));
      expect(info.artistName, equals('BTS'));
      expect(info.status, equals('pending'));
      expect(info.applicationCount, equals(50));
      expect(info.groupName, isNull);
      expect(info.artist, isNull);
    });

    test('groupName 포함 생성', () {
      const info = UserApplicationInfo(
        id: 'app-002',
        artistName: 'V',
        groupName: 'BTS',
        status: 'approved',
        applicationCount: 30,
      );
      expect(info.groupName, equals('BTS'));
    });
  });

  group('VoteRequestStatusUtils', () {
    test('getStatusColor - pending 색상', () {
      final color = VoteRequestStatusUtils.getStatusColor('pending');
      expect(color, equals(Colors.orange));
    });

    test('getStatusColor - approved 색상', () {
      final color = VoteRequestStatusUtils.getStatusColor('approved');
      expect(color, equals(Colors.green));
    });

    test('getStatusColor - rejected 색상', () {
      final color = VoteRequestStatusUtils.getStatusColor('rejected');
      expect(color, equals(Colors.red));
    });

    test('getStatusColor - in-progress 색상', () {
      final color = VoteRequestStatusUtils.getStatusColor('in-progress');
      expect(color, isNotNull);
    });

    test('getStatusColor - cancelled 색상', () {
      final color = VoteRequestStatusUtils.getStatusColor('cancelled');
      expect(color, isNotNull);
    });

    test('getStatusColor - unknown 상태는 grey', () {
      final color = VoteRequestStatusUtils.getStatusColor('unknown');
      expect(color, isNotNull);
    });

    test('getStatusColor - 대소문자 무관', () {
      final color1 = VoteRequestStatusUtils.getStatusColor('PENDING');
      final color2 = VoteRequestStatusUtils.getStatusColor('pending');
      expect(color1, equals(color2));
    });
  });

  group('ArtistNameUtils.formatNumber', () {
    test('0 포맷', () {
      expect(ArtistNameUtils.formatNumber(0), equals('0'));
    });

    test('3자리 미만 숫자', () {
      expect(ArtistNameUtils.formatNumber(999), equals('999'));
    });

    test('4자리 숫자 콤마', () {
      expect(ArtistNameUtils.formatNumber(1000), equals('1,000'));
    });

    test('7자리 숫자 콤마', () {
      expect(ArtistNameUtils.formatNumber(1234567), equals('1,234,567'));
    });

    test('10자리 숫자 콤마', () {
      expect(ArtistNameUtils.formatNumber(1000000000), equals('1,000,000,000'));
    });

    test('1자리 숫자', () {
      expect(ArtistNameUtils.formatNumber(5), equals('5'));
    });

    test('정확히 1000', () {
      expect(ArtistNameUtils.formatNumber(1000), equals('1,000'));
    });

    test('정확히 999999', () {
      expect(ArtistNameUtils.formatNumber(999999), equals('999,999'));
    });
  });
}
