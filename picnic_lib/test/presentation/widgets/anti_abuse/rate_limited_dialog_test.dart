import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/anti_abuse/rate_limited_dialog.dart';

Widget _harness(Widget child, {Locale locale = const Locale('ko')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko'), Locale('en')],
    home: child,
  );
}

Future<void> _openDialog(WidgetTester tester, String channel,
    {Locale locale = const Locale('ko')}) async {
  await tester.pumpWidget(_harness(
    Builder(builder: (ctx) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showRateLimitedDialog(ctx, channel: channel),
            child: const Text('open'),
          ),
        ),
      );
    }),
    locale: locale,
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signup channel shows partially explicit copy + CS button', (
    tester,
  ) async {
    await _openDialog(tester, 'signup');

    expect(find.textContaining('비정상 활동'), findsOneWidget);
    expect(find.text('고객센터 문의'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('ad_watch channel shows ambiguous tone, no CS button', (
    tester,
  ) async {
    await _openDialog(tester, 'ad_watch');

    expect(find.textContaining('잠시 후'), findsOneWidget);
    expect(find.text('고객센터 문의'), findsNothing);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('attendance channel shows attendance copy, no CS button',
      (tester) async {
    await _openDialog(tester, 'attendance');

    expect(find.textContaining('출석 처리'), findsOneWidget);
    expect(find.text('고객센터 문의'), findsNothing);
  });

  testWidgets('artist_request channel shows artist-request copy, no CS button',
      (tester) async {
    await _openDialog(tester, 'artist_request');

    expect(find.textContaining('아티스트 추가 요청'), findsOneWidget);
    expect(find.text('고객센터 문의'), findsNothing);
  });

  testWidgets('unknown channel falls back to ambiguous attendance copy',
      (tester) async {
    await _openDialog(tester, 'totally_unexpected_channel');

    expect(find.textContaining('출석 처리'), findsOneWidget);
    expect(find.text('고객센터 문의'), findsNothing);
  });

  testWidgets('English locale renders correctly', (tester) async {
    await _openDialog(tester, 'signup', locale: const Locale('en'));

    expect(find.textContaining('Sign-up is temporarily restricted'),
        findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);
  });

  testWidgets('OK button dismisses dialog', (tester) async {
    await _openDialog(tester, 'ad_watch');

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
