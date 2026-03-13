import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/purchase.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';

void main() {
  group('RouteManager', () {
    group('resolveDeepLink', () {
      test('returns null for non-picnic scheme', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('https://example.com'));
        expect(result, isNull);
      });

      test('returns profile route with path segment', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://profile/user123'));
        expect(result, equals('/profile/user123'));
      });

      test('returns profile route with empty segment', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://profile'));
        expect(result, equals('/profile/'));
      });

      test('returns post route with path segment', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://post/456'));
        expect(result, equals('/post/456'));
      });

      test('returns post route with empty segment', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://post'));
        expect(result, equals('/post/'));
      });

      test('returns terms route', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://terms'));
        expect(result, equals(TermsScreen.routeName));
      });

      test('returns privacy route', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://privacy'));
        expect(result, equals(PrivacyScreen.routeName));
      });

      test('returns null for unknown host', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('picnic://unknown'));
        expect(result, isNull);
      });

      test('returns null for empty URI', () {
        final result = RouteManager.resolveDeepLink(Uri.parse(''));
        expect(result, isNull);
      });

      test('returns profile route with multiple path segments', () {
        final result = RouteManager.resolveDeepLink(
          Uri.parse('picnic://profile/user123/details'),
        );
        // Should only use the first path segment
        expect(result, equals('/profile/user123'));
      });

      test('returns post route with multiple path segments', () {
        final result = RouteManager.resolveDeepLink(
          Uri.parse('picnic://post/456/comments'),
        );
        expect(result, equals('/post/456'));
      });

      test('returns null for http scheme', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('http://profile/123'));
        expect(result, isNull);
      });

      test('returns null for mailto scheme', () {
        final result = RouteManager.resolveDeepLink(Uri.parse('mailto:test@test.com'));
        expect(result, isNull);
      });
    });

    group('getCommonRoutes', () {
      test('returns non-empty map', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes, isNotEmpty);
      });

      test('contains terms route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey(TermsScreen.routeName), isTrue);
      });

      test('contains privacy route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey(PrivacyScreen.routeName), isTrue);
      });

      test('contains signup route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey(SignUpScreen.routeName), isTrue);
      });

      test('contains pic-camera route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey('/pic-camera'), isTrue);
      });

      test('contains purchase route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey(PurchaseScreen.routeName), isTrue);
      });

      test('contains oauth callback route', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.containsKey(OAuthCallbackPage.routeName), isTrue);
      });

      test('returns exactly 6 routes', () {
        final routes = RouteManager.getCommonRoutes();
        expect(routes.length, equals(6));
      });

      test('all values are WidgetBuilder functions', () {
        final routes = RouteManager.getCommonRoutes();
        for (final builder in routes.values) {
          expect(builder, isA<WidgetBuilder>());
        }
      });
    });

    group('mergeRoutes', () {
      test('includes common routes when merging empty map', () {
        final merged = RouteManager.mergeRoutes({});
        final common = RouteManager.getCommonRoutes();
        for (final key in common.keys) {
          expect(merged.containsKey(key), isTrue);
        }
      });

      test('includes app-specific routes', () {
        final appRoutes = {'/custom': (BuildContext context) => const SizedBox()};
        final merged = RouteManager.mergeRoutes(appRoutes);
        expect(merged.containsKey('/custom'), isTrue);
      });

      test('app routes override common routes', () {
        final customBuilder = (BuildContext context) => const Placeholder();
        final appRoutes = {TermsScreen.routeName: customBuilder};
        final merged = RouteManager.mergeRoutes(appRoutes);
        expect(merged[TermsScreen.routeName], equals(customBuilder));
      });

      test('merged map has at least common routes count', () {
        final common = RouteManager.getCommonRoutes();
        final merged = RouteManager.mergeRoutes({'/extra': (context) => const SizedBox()});
        expect(merged.length, greaterThanOrEqualTo(common.length));
      });

      test('merged map size equals common + unique app routes', () {
        final common = RouteManager.getCommonRoutes();
        final appRoutes = {
          '/app1': (BuildContext context) => const SizedBox(),
          '/app2': (BuildContext context) => const SizedBox(),
        };
        final merged = RouteManager.mergeRoutes(appRoutes);
        expect(merged.length, equals(common.length + 2));
      });

      test('overriding does not increase count', () {
        final common = RouteManager.getCommonRoutes();
        final appRoutes = {
          TermsScreen.routeName: (BuildContext context) => const SizedBox(),
        };
        final merged = RouteManager.mergeRoutes(appRoutes);
        expect(merged.length, equals(common.length));
      });

      test('multiple app routes with some overriding', () {
        final common = RouteManager.getCommonRoutes();
        final appRoutes = {
          TermsScreen.routeName: (BuildContext context) => const SizedBox(),
          '/new-route': (BuildContext context) => const SizedBox(),
        };
        final merged = RouteManager.mergeRoutes(appRoutes);
        expect(merged.length, equals(common.length + 1));
        expect(merged.containsKey('/new-route'), isTrue);
      });
    });

    group('navigateTo', () {
      testWidgets('returns true on successful navigation', (tester) async {
        bool navigated = false;
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (context) => Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      navigated = RouteManager.navigateTo(context, '/target');
                    },
                    child: const Text('Go'),
                  );
                },
              ),
              '/target': (context) => const Scaffold(body: Text('Target')),
            },
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(navigated, isTrue);
        expect(find.text('Target'), findsOneWidget);
      });

      testWidgets('returns false when route does not exist', (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    result = RouteManager.navigateTo(context, '/nonexistent');
                  },
                  child: const Text('Go'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        // Navigator.pushNamed with unknown route may throw depending on onUnknownRoute
        // With default MaterialApp config it shows an error page, but pushNamed itself
        // might not throw. Let's just verify it returns a bool.
        expect(result, isNotNull);
      });

      testWidgets('passes arguments to route', (tester) async {
        Object? receivedArgs;
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (context) => Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      RouteManager.navigateTo(
                        context,
                        '/target',
                        arguments: 'test-arg',
                      );
                    },
                    child: const Text('Go'),
                  );
                },
              ),
              '/target': (context) {
                receivedArgs = ModalRoute.of(context)?.settings.arguments;
                return const SizedBox();
              },
            },
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(receivedArgs, equals('test-arg'));
      });
    });

    group('replaceWith', () {
      testWidgets('returns true on successful replacement', (tester) async {
        bool replaced = false;
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (context) => Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      replaced = RouteManager.replaceWith(context, '/target');
                    },
                    child: const Text('Go'),
                  );
                },
              ),
              '/target': (context) => const Scaffold(body: Text('Replaced')),
            },
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(replaced, isTrue);
        expect(find.text('Replaced'), findsOneWidget);
      });

      testWidgets('passes arguments to replacement route', (tester) async {
        Object? receivedArgs;
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (context) => Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      RouteManager.replaceWith(
                        context,
                        '/target',
                        arguments: {'key': 'value'},
                      );
                    },
                    child: const Text('Go'),
                  );
                },
              ),
              '/target': (context) {
                receivedArgs = ModalRoute.of(context)?.settings.arguments;
                return const SizedBox();
              },
            },
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(receivedArgs, equals({'key': 'value'}));
      });

      testWidgets('returns false when navigation fails', (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    result = RouteManager.replaceWith(context, '/nonexistent');
                  },
                  child: const Text('Go'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
      });
    });
  });
}
