import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  // ───────────────────────────────────────────────
  // ArtistApplicationInfo
  // ───────────────────────────────────────────────
  group('ArtistApplicationInfo', () {
    test('creates with required fields and default isSubmitting', () {
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

    test('creates with all fields including isSubmitting', () {
      const info = ArtistApplicationInfo(
        artistName: 'BLACKPINK',
        applicationCount: 50,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );
      expect(info.artistName, 'BLACKPINK');
      expect(info.applicationCount, 50);
      expect(info.applicationStatus, 'approved');
      expect(info.isAlreadyInVote, isTrue);
      expect(info.isSubmitting, isTrue);
    });

    group('copyWith', () {
      const original = ArtistApplicationInfo(
        artistName: 'TWICE',
        applicationCount: 75,
        applicationStatus: 'approved',
        isAlreadyInVote: true,
        isSubmitting: true,
      );

      test('updates artistName only', () {
        final updated = original.copyWith(artistName: 'NewJeans');
        expect(updated.artistName, 'NewJeans');
        expect(updated.applicationCount, 75);
        expect(updated.applicationStatus, 'approved');
        expect(updated.isAlreadyInVote, isTrue);
        expect(updated.isSubmitting, isTrue);
      });

      test('updates applicationCount only', () {
        final updated = original.copyWith(applicationCount: 200);
        expect(updated.applicationCount, 200);
        expect(updated.artistName, 'TWICE');
      });

      test('updates applicationStatus only', () {
        final updated = original.copyWith(applicationStatus: 'rejected');
        expect(updated.applicationStatus, 'rejected');
        expect(updated.artistName, 'TWICE');
      });

      test('updates isAlreadyInVote only', () {
        final updated = original.copyWith(isAlreadyInVote: false);
        expect(updated.isAlreadyInVote, isFalse);
        expect(updated.artistName, 'TWICE');
      });

      test('updates isSubmitting only', () {
        final updated = original.copyWith(isSubmitting: false);
        expect(updated.isSubmitting, isFalse);
        expect(updated.artistName, 'TWICE');
      });

      test('updates all fields at once', () {
        final updated = original.copyWith(
          artistName: 'IVE',
          applicationCount: 999,
          applicationStatus: 'pending',
          isAlreadyInVote: false,
          isSubmitting: false,
        );
        expect(updated.artistName, 'IVE');
        expect(updated.applicationCount, 999);
        expect(updated.applicationStatus, 'pending');
        expect(updated.isAlreadyInVote, isFalse);
        expect(updated.isSubmitting, isFalse);
      });

      test('returns new instance preserving unchanged fields when no args', () {
        final updated = original.copyWith();
        expect(updated.artistName, original.artistName);
        expect(updated.applicationCount, original.applicationCount);
        expect(updated.applicationStatus, original.applicationStatus);
        expect(updated.isAlreadyInVote, original.isAlreadyInVote);
        expect(updated.isSubmitting, original.isSubmitting);
      });
    });
  });

  // ───────────────────────────────────────────────
  // UserApplicationInfo
  // ───────────────────────────────────────────────
  group('UserApplicationInfo', () {
    test('creates with required fields only', () {
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

    test('creates with zero applicationCount', () {
      const info = UserApplicationInfo(
        id: 'app-3',
        artistName: 'Solo',
        status: 'pending',
        applicationCount: 0,
      );
      expect(info.applicationCount, 0);
    });
  });

  // ───────────────────────────────────────────────
  // VoteRequestStatusUtils.getStatusColor (pure)
  // ───────────────────────────────────────────────
  group('VoteRequestStatusUtils.getStatusColor', () {
    setUp(() {
      initTestColors();
    });

    test('returns orange for pending', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('pending'),
        Colors.orange,
      );
    });

    test('returns green for approved', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('approved'),
        Colors.green,
      );
    });

    test('returns red for rejected', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('rejected'),
        Colors.red,
      );
    });

    test('returns primary500 for in-progress', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('in-progress'),
        AppColors.primary500,
      );
    });

    test('returns grey400 for cancelled', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('cancelled'),
        AppColors.grey400,
      );
    });

    test('returns grey400 for unknown status', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('something-else'),
        AppColors.grey400,
      );
    });

    test('returns grey400 for empty string', () {
      expect(
        VoteRequestStatusUtils.getStatusColor(''),
        AppColors.grey400,
      );
    });

    test('is case insensitive', () {
      expect(
        VoteRequestStatusUtils.getStatusColor('PENDING'),
        Colors.orange,
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('Approved'),
        Colors.green,
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('REJECTED'),
        Colors.red,
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('In-Progress'),
        AppColors.primary500,
      );
      expect(
        VoteRequestStatusUtils.getStatusColor('CANCELLED'),
        AppColors.grey400,
      );
    });
  });

  // ───────────────────────────────────────────────
  // ArtistNameUtils.formatNumber (pure)
  // ───────────────────────────────────────────────
  group('ArtistNameUtils.formatNumber', () {
    test('formats thousands', () {
      expect(ArtistNameUtils.formatNumber(1000), '1,000');
    });

    test('formats millions', () {
      expect(ArtistNameUtils.formatNumber(1000000), '1,000,000');
    });

    test('formats multi-digit millions', () {
      expect(ArtistNameUtils.formatNumber(12345678), '12,345,678');
    });

    test('does not format numbers below 1000', () {
      expect(ArtistNameUtils.formatNumber(0), '0');
      expect(ArtistNameUtils.formatNumber(1), '1');
      expect(ArtistNameUtils.formatNumber(99), '99');
      expect(ArtistNameUtils.formatNumber(100), '100');
      expect(ArtistNameUtils.formatNumber(999), '999');
    });

    test('formats exactly 10000', () {
      expect(ArtistNameUtils.formatNumber(10000), '10,000');
    });

    test('formats large numbers', () {
      expect(ArtistNameUtils.formatNumber(1000000000), '1,000,000,000');
    });
  });

  // ───────────────────────────────────────────────
  // VoteRequestStatusUtils.getStatusText (needs context)
  // ───────────────────────────────────────────────
  group('VoteRequestStatusUtils.getStatusText', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns Korean text for pending (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('pending');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '대기중');
    });

    testWidgets('returns Korean text for approved (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('approved');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '승인됨');
    });

    testWidgets('returns Korean text for rejected (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('rejected');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '거절됨');
    });

    testWidgets('returns Korean text for in-progress (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('in-progress');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '진행중');
    });

    testWidgets('returns Korean text for cancelled (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('cancelled');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '취소됨');
    });

    testWidgets('returns Korean text for unknown status (ko locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('something-else');
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '알 수 없음');
    });

    testWidgets('returns English text for pending (en locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('pending');
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'Pending');
    });

    testWidgets('returns English text for approved (en locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('approved');
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'Approved');
    });

    testWidgets('returns English text for rejected (en locale)',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.getStatusText('rejected');
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'Rejected');
    });

    testWidgets('is case insensitive', (tester) async {
      String? lower;
      String? upper;
      String? mixed;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            lower = VoteRequestStatusUtils.getStatusText('pending');
            upper = VoteRequestStatusUtils.getStatusText('PENDING');
            mixed = VoteRequestStatusUtils.getStatusText('Pending');
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(lower, equals(upper));
      expect(lower, equals(mixed));
    });
  });

  // ───────────────────────────────────────────────
  // VoteRequestStatusUtils.shouldShowApplicationButton (needs context)
  // ───────────────────────────────────────────────
  group('VoteRequestStatusUtils.shouldShowApplicationButton', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns false when isAlreadyInVote is true regardless of status',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('rejected');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              true,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('returns true for rejected status when not in vote',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('rejected');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('returns true for cancelled status when not in vote',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('cancelled');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('returns false for pending status', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('pending');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('returns false for approved status', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('approved');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('returns false for in-progress status', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('in-progress');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('returns true for can_apply status', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(navigatorKey.currentContext!);
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              l10n.vote_item_request_can_apply,
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('returns false for unrecognized status that is not can_apply',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              'some-random-status',
              false,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets(
        'returns false for cancelled status when isAlreadyInVote is true',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final status =
                VoteRequestStatusUtils.getStatusText('cancelled');
            result = VoteRequestStatusUtils.shouldShowApplicationButton(
              status,
              true,
            );
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  // ───────────────────────────────────────────────
  // ArtistNameUtils.getDisplayName (needs context)
  // ───────────────────────────────────────────────
  group('ArtistNameUtils.getDisplayName', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns empty string for empty map', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({});
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '');
    });

    testWidgets('returns korean name first for ko locale', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '방탄소년단',
              'en': 'BTS',
            });
            return const SizedBox();
          }),
          locale: const Locale('ko'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '방탄소년단 (BTS)');
    });

    testWidgets('returns english name first for en locale', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '방탄소년단',
              'en': 'BTS',
            });
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'BTS (방탄소년단)');
    });

    testWidgets('returns only korean when english is empty', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '뉴진스',
              'en': '',
            });
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '뉴진스');
    });

    testWidgets('returns only english when korean is empty', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '',
              'en': 'NewJeans',
            });
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'NewJeans');
    });

    testWidgets('returns empty when both names are empty strings',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '',
              'en': '',
            });
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '');
    });

    testWidgets('handles missing ko key gracefully', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({'en': 'BTS'});
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'BTS');
    });

    testWidgets('handles missing en key gracefully', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({'ko': '방탄소년단'});
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '방탄소년단');
    });

    testWidgets('handles map with unrelated keys only', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({'ja': 'ビーティーエス'});
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '');
    });

    testWidgets('non-ko locale treats english as primary', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ArtistNameUtils.getDisplayName({
              'ko': '아이브',
              'en': 'IVE',
            });
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 'IVE (아이브)');
    });
  });
}
