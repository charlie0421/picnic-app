import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
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

    test('in-progress returns primary500', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('in-progress'),
        AppColors.primary500,
      );
    });

    test('cancelled returns grey400', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('cancelled'),
        AppColors.grey400,
      );
    });

    test('unknown status returns grey400', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('some_random_status'),
        AppColors.grey400,
      );
    });

    test('case insensitive - PENDING', () {
      expect(VoteRequestStatusUtils.getStatusColor('PENDING'), Colors.orange);
    });

    test('case insensitive - Approved', () {
      expect(VoteRequestStatusUtils.getStatusColor('Approved'), Colors.green);
    });

    test('case insensitive - IN-PROGRESS', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('IN-PROGRESS'),
        AppColors.primary500,
      );
    });

    test('empty string returns grey400', () {
      expect(
        VoteRequestStatusUtils.getStatusColor(''),
        AppColors.grey400,
      );
    });
  });
}
