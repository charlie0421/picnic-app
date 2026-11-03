import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';

/// PICNIC-777 regression: opening a dialog above a page must not re-run the
/// page's didChangeDependencies. Portal pages call settingNavigation from
/// didChangeDependencies, so a spurious call flips the header/bottom nav.
class _Probe extends StatefulWidget {
  const _Probe({required this.onDependenciesChanged});
  final VoidCallback onDependenciesChanged;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onDependenciesChanged();
  }

  @override
  Widget build(BuildContext context) {
    // Real pages use Material widgets, which depend on Theme.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const SizedBox.expand(),
    );
  }
}

void main() {
  testWidgets('rebuilding the app with a freshly applied theme does not re-run '
      'didChangeDependencies of the page', (tester) async {
    var count = 0;
    Widget app() => MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        padding: EdgeInsets.only(bottom: 48),
        viewPadding: EdgeInsets.only(bottom: 48),
      ),
      child: MaterialApp(
        theme: AppBuilder.applySystemNavigationBarInset(ThemeData()),
        home: _Probe(onDependenciesChanged: () => count++),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final before = count;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(count - before, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  Future<int> countAfterDialog(
    WidgetTester tester, {
    required bool withInset,
  }) async {
    var count = 0;
    final theme = ThemeData();
    late BuildContext homeContext;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: MaterialApp(
          theme: withInset
              ? AppBuilder.applySystemNavigationBarInset(theme)
              : theme,
          home: Builder(
            builder: (context) {
              homeContext = context;
              return _Probe(onDependenciesChanged: () => count++);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = count;
    showDialog<void>(
      context: homeContext,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    return count - before;
  }

  testWidgets(
    'baseline: a dialog does not re-run didChangeDependencies of the page below',
    (tester) async {
      expect(await countAfterDialog(tester, withInset: false), 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'with the inset theme: a dialog does not re-run didChangeDependencies',
    (tester) async {
      expect(await countAfterDialog(tester, withInset: true), 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
