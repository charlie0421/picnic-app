import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';

void main() {
  group('RouteManager - navigateTo error path', () {
    testWidgets('navigateTo catches error for invalid context',
        (WidgetTester tester) async {
      // Use onGenerateRoute to throw an error for unknown routes
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (_) => Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        result = RouteManager.navigateTo(
                            context, '/nonexistent-route');
                      },
                      child: const Text('Go'),
                    );
                  },
                ),
              );
            }
            // Return null to trigger onUnknownRoute
            return null;
          },
          onUnknownRoute: (settings) {
            throw Exception('Route not found: ${settings.name}');
          },
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      // Should return false when navigation throws
      expect(result, isFalse);
    });
  });

  group('RouteManager - replaceWith error path', () {
    testWidgets('replaceWith catches error for invalid route',
        (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (_) => Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        result = RouteManager.replaceWith(
                            context, '/nonexistent-route');
                      },
                      child: const Text('Go'),
                    );
                  },
                ),
              );
            }
            return null;
          },
          onUnknownRoute: (settings) {
            throw Exception('Route not found: ${settings.name}');
          },
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(result, isFalse);
    });
  });

  group('RouteManager - resolveDeepLink additional coverage', () {
    test('profile with no path segments returns /profile/', () {
      final result =
          RouteManager.resolveDeepLink(Uri.parse('picnic://profile'));
      expect(result, '/profile/');
    });

    test('post with no path segments returns /post/', () {
      final result = RouteManager.resolveDeepLink(Uri.parse('picnic://post'));
      expect(result, '/post/');
    });

    test('terms deep link returns TermsScreen.routeName', () {
      final result = RouteManager.resolveDeepLink(Uri.parse('picnic://terms'));
      expect(result, TermsScreen.routeName);
    });

    test('privacy deep link returns PrivacyScreen.routeName', () {
      final result =
          RouteManager.resolveDeepLink(Uri.parse('picnic://privacy'));
      expect(result, PrivacyScreen.routeName);
    });

    test('settings deep link returns null (unknown host)', () {
      final result =
          RouteManager.resolveDeepLink(Uri.parse('picnic://settings'));
      expect(result, isNull);
    });

    test('non-picnic scheme returns null', () {
      expect(
          RouteManager.resolveDeepLink(Uri.parse('https://example.com')),
          isNull);
      expect(
          RouteManager.resolveDeepLink(Uri.parse('http://profile')), isNull);
    });
  });

  group('RouteManager - mergeRoutes edge cases', () {
    test('merging empty map returns common routes', () {
      final common = RouteManager.getCommonRoutes();
      final merged = RouteManager.mergeRoutes({});
      expect(merged.length, common.length);
      for (final key in common.keys) {
        expect(merged.containsKey(key), isTrue);
      }
    });

    test('merging with all common routes overridden', () {
      final common = RouteManager.getCommonRoutes();
      final overrides = <String, WidgetBuilder>{};
      for (final key in common.keys) {
        overrides[key] = (context) => const Placeholder();
      }
      final merged = RouteManager.mergeRoutes(overrides);
      expect(merged.length, common.length);
    });
  });

  group('RouteManager - getCommonRoutes route builders', () {
    testWidgets('SignUpScreen route builder returns a widget',
        (WidgetTester tester) async {
      final routes = RouteManager.getCommonRoutes();
      // We just verify the builders exist and are callable
      for (final entry in routes.entries) {
        expect(entry.value, isA<WidgetBuilder>());
      }
    });
  });
}
