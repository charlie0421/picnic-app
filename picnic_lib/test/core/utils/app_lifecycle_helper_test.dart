import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_helper.dart';

void main() {
  group('AppLifecycleHelper', () {
    group('classifyBranchUri', () {
      test('returns ignore for null URI', () {
        expect(
          AppLifecycleHelper.classifyBranchUri(null),
          BranchUriAction.ignore,
        );
      });

      test('returns deeplink for picnic scheme', () {
        final uri = Uri.parse('picnic://some/path');
        expect(
          AppLifecycleHelper.classifyBranchUri(uri),
          BranchUriAction.deeplink,
        );
      });

      test('returns unsupported for https scheme', () {
        final uri = Uri.parse('https://example.com');
        expect(
          AppLifecycleHelper.classifyBranchUri(uri),
          BranchUriAction.unsupported,
        );
      });

      test('returns unsupported for http scheme', () {
        final uri = Uri.parse('http://example.com');
        expect(
          AppLifecycleHelper.classifyBranchUri(uri),
          BranchUriAction.unsupported,
        );
      });

      test('returns unsupported for empty scheme', () {
        final uri = Uri.parse('/just/a/path');
        expect(
          AppLifecycleHelper.classifyBranchUri(uri),
          BranchUriAction.unsupported,
        );
      });
    });

    group('isAppDeepLink', () {
      test('returns true for picnic scheme URI', () {
        expect(
          AppLifecycleHelper.isAppDeepLink(Uri.parse('picnic://home')),
          isTrue,
        );
      });

      test('returns false for null', () {
        expect(AppLifecycleHelper.isAppDeepLink(null), isFalse);
      });

      test('returns false for non-picnic scheme', () {
        expect(
          AppLifecycleHelper.isAppDeepLink(Uri.parse('https://example.com')),
          isFalse,
        );
      });
    });

    group('extractDeepLinkPath', () {
      test('returns path for valid deep link', () {
        expect(
          AppLifecycleHelper.extractDeepLinkPath(
              Uri.parse('picnic://vote/123')),
          '/123',
        );
      });

      test('returns null for null URI', () {
        expect(AppLifecycleHelper.extractDeepLinkPath(null), isNull);
      });

      test('returns null for non-picnic URI', () {
        expect(
          AppLifecycleHelper.extractDeepLinkPath(
              Uri.parse('https://example.com/path')),
          isNull,
        );
      });

      test('returns empty path for root deep link', () {
        expect(
          AppLifecycleHelper.extractDeepLinkPath(Uri.parse('picnic://')),
          isEmpty,
        );
      });
    });

    group('isValidRouteMap', () {
      test('returns true for non-empty map', () {
        expect(
          AppLifecycleHelper.isValidRouteMap({'/home': 'widget'}),
          isTrue,
        );
      });

      test('returns false for empty map', () {
        expect(AppLifecycleHelper.isValidRouteMap({}), isFalse);
      });
    });

    group('getRouteCount', () {
      test('returns correct count', () {
        expect(
          AppLifecycleHelper.getRouteCount({'/a': 1, '/b': 2, '/c': 3}),
          3,
        );
      });

      test('returns 0 for empty map', () {
        expect(AppLifecycleHelper.getRouteCount({}), 0);
      });
    });

    test('appUriScheme is picnic', () {
      expect(AppLifecycleHelper.appUriScheme, 'picnic');
    });
  });

  group('BranchUriAction', () {
    test('has expected values', () {
      expect(BranchUriAction.values.length, 3);
      expect(BranchUriAction.values, contains(BranchUriAction.deeplink));
      expect(BranchUriAction.values, contains(BranchUriAction.unsupported));
      expect(BranchUriAction.values, contains(BranchUriAction.ignore));
    });
  });
}
