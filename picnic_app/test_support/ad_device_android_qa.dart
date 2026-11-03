// Run only through scripts/qa/run_ad_device_android.py in an isolated QA package.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/anti_abuse/rate_limited_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_flow.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const base = 'http://127.0.0.1:${String.fromEnvironment('QA_PORT')}';
Future<Map<String, dynamic>> control(
  String name, [
  Map<String, dynamic> body = const {},
]) async {
  final response = await http.post(
    Uri.parse('$base/qa/$name'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  expect(response.statusCode, 200);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'physical Android device policy and localized restriction contract',
    (tester) async {
      // Require the real Android bridge, not the UUID fallback path.
      final nativeId = await const MethodChannel(
        'picnic/device_id',
      ).invokeMethod<String>('getAndroidId');
      expect(nativeId, isNotEmpty);
      final device = await DeviceManager.getDeviceId();
      expect(await DeviceManager.getDeviceId(), device);
      final clients = <SupabaseClient>[];
      var allowed = 0;
      var denied = 0;
      Future<void> request(
        int account,
        String channel,
        bool shouldAllow,
      ) async {
        final client = SupabaseClient(
          base,
          'synthetic-local-only-key',
          headers: {'X-QA-Account': '$account'},
        );
        clients.add(client);
        final repository = AdRewardRepository(client);
        try {
          if (channel == 'ADMOB') {
            await repository.createAdmobClaim(
              platform: 'android',
              placementId: 'qa',
              clientRequestId: 'qa',
            );
          } else if (channel == 'PANGLE') {
            await repository.createPangleClaim(
              platform: 'android',
              placementId: 'qa',
              clientRequestId: 'qa',
            );
          } else {
            await InternalShortformIssueFlow(
              currentOwner: () => 'synthetic-$account',
              invokeIssue: () async => (await client.functions.invoke(
                'ad-shortform-issue',
                headers: {'X-Device-Id': await DeviceManager.getDeviceId()},
              )).data,
              persist: (_, _) async {},
              rewriteVideoUrl: (url) => url!,
            ).issue();
          }
          expect(
            shouldAllow,
            isTrue,
            reason: '$channel account $account unexpectedly allowed',
          );
          allowed++;
        } on FunctionException catch (error) {
          expect(
            shouldAllow,
            isFalse,
            reason: '$channel account $account unexpectedly restricted',
          );
          final mapped = mapToAntiAbuseException(error);
          expect(mapped, isA<AntiAbuseException>());
          expect(
            (mapped as AntiAbuseException).rawCode,
            'AD_DEVICE_ACCOUNT_LIMIT',
          );
          denied++;
        }
      }

      const channels = ['INTERNAL', 'ADMOB', 'PANGLE'];
      for (var account = 1; account <= 4; account++) {
        for (final channel in channels) {
          await request(account, channel, account <= 3);
        }
      }
      // The fourth account must not retroactively restrict the first three.
      for (var account = 1; account <= 3; account++) {
        for (final channel in channels) {
          await request(account, channel, true);
        }
      }
      await control('expire-first');
      for (final channel in channels) {
        await request(4, channel, true);
        await request(1, channel, false);
      }

      await binding.convertFlutterSurfaceToImage();
      for (final locale in AppLocalizations.supportedLocales) {
        final scale = locale.languageCode == 'es' ? 2.0 : 1.0;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showRateLimitedDialog(
                      context,
                      channel: 'ad_watch',
                      rawCode: 'AD_DEVICE_ACCOUNT_LIMIT',
                    ),
                    child: const Text('Open restriction'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open restriction'));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(AlertDialog));
        final l10n = AppLocalizations.of(context);
        expect(
          find.text(l10n.error_ad_device_account_restricted_message),
          findsOneWidget,
        );
        expect(find.text('AD_DEVICE_ACCOUNT_LIMIT'), findsNothing);
        expect(tester.takeException(), isNull);
        if (['ko', 'en', 'es'].contains(locale.languageCode) &&
            locale.countryCode == null) {
          final name = locale.languageCode == 'es'
              ? 'es-large'
              : locale.languageCode;
          await control('screenshot', {
            'name': name,
            'png': base64Encode(await binding.takeScreenshot(name)),
          });
        }
        await tester.tap(find.text(l10n.dialog_button_ok));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }
      for (final client in clients) {
        await client.dispose();
      }
      final result = await control('result', {
        'allowed': allowed,
        'denied': denied,
        'locales': AppLocalizations.supportedLocales.length,
        'native_device_id': true,
      });
      expect(result['distinct_devices'], 1);
      expect(allowed, 21);
      expect(denied, 6);
    },
  );
}
