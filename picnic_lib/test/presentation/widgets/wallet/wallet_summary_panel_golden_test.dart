import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final walletIconImages = <String, ui.Image>{};

Future<void> loadWalletIconImages() async {
  for (final asset in const [
    'assets/icons/store/currency_star_candy.png',
    'assets/icons/store/currency_bonus_star_candy.png',
    'assets/icons/store/currency_cotton_candy.png',
  ]) {
    final codec = await ui.instantiateImageCodec(File(asset).readAsBytesSync());
    walletIconImages[asset] = (await codec.getNextFrame()).image;
    codec.dispose();
  }
}

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
  child: MaterialApp(
    theme: ThemeData(fontFamily: 'Pretendard'),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(
      child: WalletSummaryPanel(
        iconBuilder: (asset, dimension) => RawImage(
          image: walletIconImages[asset],
          width: dimension,
          height: dimension,
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await loadTestFonts();
    await loadWalletIconImages();
  });

  testWidgets('three-currency wallet golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 510);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildWalletGoldenApp(walletSummaryFixture));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(WalletSummaryPanel),
      matchesGoldenFile('../../../goldens/wallet_summary_panel.png'),
    );
  });
}
