import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/navigation/app_route_observer.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

/// PICNIC-777: pages that mix in [RouteAwareStateMixin] re-apply their
/// navigation state from didChangeDependencies. Subscribing through
/// `ModalRoute.of` made every page depend on the route's status, so opening
/// any dialog re-ran didChangeDependencies on all stacked pages at once and the
/// last post-frame callback won (home header shown over vote detail). The
/// mixin must subscribe without creating that dependency.
class _Page extends StatefulWidget {
  const _Page({required this.observer, required this.events, this.name});
  final AppRouteObserver observer;
  final List<String> events;
  final String? name;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with RouteAwareStateMixin<_Page> {
  @override
  RouteObserver<PageRoute<dynamic>> get routeObserver => widget.observer;

  void _log(String event) =>
      widget.events.add(widget.name == null ? event : '${widget.name}:$event');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _log('dcd');
  }

  @override
  void onRoutePushed() {
    super.onRoutePushed();
    _log('pushed');
  }

  @override
  void onRoutePushNext() {
    super.onRoutePushNext();
    _log('pushNext');
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _log('popNext');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  late AppRouteObserver observer;
  late List<String> events;
  late BuildContext pageContext;

  Future<void> pumpApp(WidgetTester tester) async {
    observer = AppRouteObserver();
    events = [];
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            pageContext = context;
            return _Page(observer: observer, events: events);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppRouteObserver.currentPageRoute', () {
    testWidgets('tracks the top-most PageRoute through push and pop', (
      tester,
    ) async {
      await pumpApp(tester);
      final home = ModalRoute.of(pageContext);
      expect(observer.currentPageRoute, same(home));

      final pushed = MaterialPageRoute<void>(builder: (_) => const SizedBox());
      Navigator.of(pageContext).push(pushed);
      await tester.pumpAndSettle();
      expect(observer.currentPageRoute, same(pushed));

      Navigator.of(pageContext).pop();
      await tester.pumpAndSettle();
      expect(observer.currentPageRoute, same(home));
    });

    testWidgets('ignores popup routes such as dialogs', (tester) async {
      await pumpApp(tester);
      final home = ModalRoute.of(pageContext);
      showDialog<void>(
        context: pageContext,
        builder: (_) => const AlertDialog(content: Text('d')),
      );
      await tester.pumpAndSettle();
      expect(observer.currentPageRoute, same(home));
    });
  });

  group('RouteAwareStateMixin', () {
    testWidgets('subscribes once and reports pushed on first build', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(events, ['pushed', 'dcd']);
    });

    testWidgets('opening a dialog does not re-run didChangeDependencies', (
      tester,
    ) async {
      await pumpApp(tester);
      events.clear();
      showDialog<void>(
        context: pageContext,
        builder: (_) => const AlertDialog(content: Text('d')),
      );
      await tester.pumpAndSettle();
      Navigator.of(pageContext).pop();
      await tester.pumpAndSettle();
      expect(events, isEmpty);
    });

    testWidgets('still receives pushNext and popNext for page routes', (
      tester,
    ) async {
      await pumpApp(tester);
      events.clear();
      Navigator.of(
        pageContext,
      ).push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
      await tester.pumpAndSettle();
      expect(events, ['pushNext']);
      Navigator.of(pageContext).pop();
      await tester.pumpAndSettle();
      expect(events, ['pushNext', 'popNext']);
    });

    testWidgets(
      'stacked pages get popNext in subscription order, so the page pushed '
      'last applies its navigation state last',
      (tester) async {
        // Portal keeps its pages in an IndexedStack inside one PageRoute, so
        // they all subscribe to that route. RouteObserver notifies subscribers
        // in insertion order (LinkedHashSet), which is the build order: the
        // page pushed later is notified later and its post-frame
        // settingNavigation wins deterministically.
        final obs = AppRouteObserver();
        final ev = <String>[];
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [obs],
            home: Builder(
              builder: (context) {
                ctx = context;
                return IndexedStack(
                  index: 1,
                  children: [
                    _Page(observer: obs, events: ev, name: 'home'),
                    _Page(observer: obs, events: ev, name: 'detail'),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        ev.clear();
        Navigator.of(
          ctx,
        ).push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
        await tester.pumpAndSettle();
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();
        expect(ev, [
          'home:pushNext',
          'detail:pushNext',
          'home:popNext',
          'detail:popNext',
        ]);
      },
    );

    testWidgets('falls back to ModalRoute.of when no observer route is known', (
      tester,
    ) async {
      // A plain harness without navigatorObservers (most existing widget
      // tests) must keep working: the page still gets `pushed`.
      final localObserver = AppRouteObserver();
      final localEvents = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: _Page(observer: localObserver, events: localEvents),
        ),
      );
      await tester.pumpAndSettle();
      expect(localEvents, ['pushed', 'dcd']);
    });
  });
}
