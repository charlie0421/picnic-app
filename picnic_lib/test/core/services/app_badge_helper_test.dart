import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/app_badge_helper.dart';

void main() {
  group('AppBadgeHelper', () {
    group('determineBadgeAction', () {
      test('returns remove when count is 0', () {
        expect(
          AppBadgeHelper.determineBadgeAction(0),
          BadgeUpdateAction.remove,
        );
      });

      test('returns remove when count is negative', () {
        expect(
          AppBadgeHelper.determineBadgeAction(-1),
          BadgeUpdateAction.remove,
        );
      });

      test('returns update when count is positive', () {
        expect(
          AppBadgeHelper.determineBadgeAction(5),
          BadgeUpdateAction.update,
        );
      });

      test('returns update when count is 1', () {
        expect(
          AppBadgeHelper.determineBadgeAction(1),
          BadgeUpdateAction.update,
        );
      });

      test('returns update for large count', () {
        expect(
          AppBadgeHelper.determineBadgeAction(999),
          BadgeUpdateAction.update,
        );
      });
    });

    group('shouldProceedWithBadge', () {
      test('returns false for web', () {
        expect(
          AppBadgeHelper.shouldProceedWithBadge(
            isWeb: true,
            isIOS: false,
            isAndroid: false,
          ),
          isFalse,
        );
      });

      test('returns true for iOS', () {
        expect(
          AppBadgeHelper.shouldProceedWithBadge(
            isWeb: false,
            isIOS: true,
            isAndroid: false,
          ),
          isTrue,
        );
      });

      test('returns true for Android', () {
        expect(
          AppBadgeHelper.shouldProceedWithBadge(
            isWeb: false,
            isIOS: false,
            isAndroid: true,
          ),
          isTrue,
        );
      });

      test('returns false for desktop', () {
        expect(
          AppBadgeHelper.shouldProceedWithBadge(
            isWeb: false,
            isIOS: false,
            isAndroid: false,
          ),
          isFalse,
        );
      });

      test('returns false for web even if iOS is true', () {
        expect(
          AppBadgeHelper.shouldProceedWithBadge(
            isWeb: true,
            isIOS: true,
            isAndroid: false,
          ),
          isFalse,
        );
      });
    });

    group('shouldUseCachedSupport', () {
      test('returns true when already checked', () {
        expect(
          AppBadgeHelper.shouldUseCachedSupport(checkedSupport: true),
          isTrue,
        );
      });

      test('returns false when not checked', () {
        expect(
          AppBadgeHelper.shouldUseCachedSupport(checkedSupport: false),
          isFalse,
        );
      });
    });

    group('calculateBadgeCount', () {
      test('returns 0 when no user', () {
        expect(
          AppBadgeHelper.calculateBadgeCount(hasUser: false, rowCount: 10),
          0,
        );
      });

      test('returns row count when user exists', () {
        expect(
          AppBadgeHelper.calculateBadgeCount(hasUser: true, rowCount: 5),
          5,
        );
      });

      test('returns 0 when user exists but no rows', () {
        expect(
          AppBadgeHelper.calculateBadgeCount(hasUser: true, rowCount: 0),
          0,
        );
      });
    });

    group('normalizeBadgeCount', () {
      test('returns 0 for negative count', () {
        expect(AppBadgeHelper.normalizeBadgeCount(-5), 0);
      });

      test('returns same value for 0', () {
        expect(AppBadgeHelper.normalizeBadgeCount(0), 0);
      });

      test('returns same value for positive count', () {
        expect(AppBadgeHelper.normalizeBadgeCount(10), 10);
      });
    });
  });

  group('BadgeUpdateAction', () {
    test('has expected values', () {
      expect(BadgeUpdateAction.values.length, 2);
      expect(BadgeUpdateAction.values, contains(BadgeUpdateAction.remove));
      expect(BadgeUpdateAction.values, contains(BadgeUpdateAction.update));
    });
  });
}
