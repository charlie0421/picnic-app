import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';

import '../../../helpers/load_test_fonts.dart';

Map<String, dynamic> loadGoldenFixture(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

final walletSummaryFixture = WalletSummaryModel.fromJson(
  loadGoldenFixture('test/fixtures/wallet_contracts/wallet_summary_v1.json'),
);

class GoldenAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (!key.contains('assets/icons/store/currency_')) {
      return rootBundle.load(key);
    }
    final relativePath = key.replaceFirst('packages/picnic_lib/', '');
    final bytes = await File(relativePath).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

final goldenAssetBundle = GoldenAssetBundle();

class GoldenWalletSummary extends WalletSummary {
  GoldenWalletSummary(this.value);
  final WalletSummaryModel value;

  @override
  Future<WalletSummaryModel> build() async => value;
}

Widget buildWalletGoldenApp(WalletSummaryModel wallet) => ProviderScope(
  overrides: [
    walletSummaryProvider.overrideWith(() => GoldenWalletSummary(wallet)),
  ],
  child: DefaultAssetBundle(
    bundle: goldenAssetBundle,
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'Pretendard'),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Material(child: WalletSummaryPanel()),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('three-currency wallet golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 510);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildWalletGoldenApp(walletSummaryFixture));
    final context = tester.element(find.byType(WalletSummaryPanel));
    for (final asset in const [
      'assets/icons/store/currency_star_candy.png',
      'assets/icons/store/currency_bonus_star_candy.png',
      'assets/icons/store/currency_cotton_candy.png',
    ]) {
      await tester.runAsync(
        () => precacheImage(
          AssetImage(asset, package: 'picnic_lib', bundle: goldenAssetBundle),
          context,
        ),
      );
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(3));
    final amount = find.text('9,007,199,254,740,993');
    expect(amount, findsOneWidget);
    expect(
      find.ancestor(of: amount, matching: find.byType(FittedBox)),
      findsOneWidget,
    );
    await expectLater(
      find.byType(WalletSummaryPanel),
      matchesGoldenFile('../../../goldens/wallet_summary_panel.png'),
    );
  });
}
