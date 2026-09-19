import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

// PICNIC-2727.
//
// Both buttons are pinned to one size (minimumSize == maximumSize, 120.w x 32)
// and the label plus icon inside was laid out at its natural width, so a
// localized label longer than the box ran out of it: 58px for Spanish and
// 128px for Bengali on an 851-wide window at 2.0x. Every caller in the app
// uses the default size and the same two localized strings, so this widget on
// its own stands in for all six screens that show it.
void main() {
  setUpAll(initTestColors);

  // Every locale with an arb file.
  const locales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('th'),
    Locale('my'),
    Locale('ja'),
    Locale('id'),
    Locale('vi'),
    Locale('fil'),
    Locale('es'),
    Locale('bn'),
    Locale('bn', 'BD'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];
  // The width changes what 120.w is; 851 is where the reported overflow lived.
  const widths = <double>[280, 393, 851];
  const textScales = <double>[1.0, 1.3, 2.0];

  Future<List<String>> pumpAt(
    WidgetTester tester, {
    required Locale locale,
    required double width,
    required double textScale,
    bool legacy = false,
  }) async {
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final original = FlutterError.onError;
    // Restore the handler as soon as the frame is laid out, not in a
    // teardown. If an expectation fails while this handler is still
    // installed, the runner stalls until its 10-minute timeout.
    FlutterError.onError = (details) {
      final text = details.exception.toString();
      if (text.contains('overflowed')) {
        overflows.add(text.split('\n').first);
        return;
      }
      if (text.contains('Unable to load asset')) return;
      original?.call(details);
    };
    try {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Center(
              child: legacy
                  ? _LegacyShareSection(
                      saveButtonText: AppLocalizations.of(context).save,
                      shareButtonText: AppLocalizations.of(context).share,
                      onSave: () {},
                      onShare: () {},
                    )
                  : ShareSection(
                      saveButtonText: AppLocalizations.of(context).save,
                      shareButtonText: AppLocalizations.of(context).share,
                      onSave: () {},
                      onShare: () {},
                    ),
            ),
          ),
          locale: locale,
          textScaler: TextScaler.linear(textScale),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = original;
    }
    return overflows;
  }

  group('PICNIC-2727 save and share fit their buttons', () {
    for (final locale in locales) {
      final tag = locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';
      for (final width in widths) {
        for (final textScale in textScales) {
          final label = '$tag ${width.toInt()}w ${textScale}x';
          testWidgets('$label has no overflow', (tester) async {
            final overflows = await pumpAt(
              tester,
              locale: locale,
              width: width,
              textScale: textScale,
            );
            expect(
              overflows,
              isEmpty,
              reason: '$label: the label ran out of its fixed-size button',
            );
          });
        }
      }
    }
  });

  group('PICNIC-2727 labels that already fit are left alone', () {
    // Korean at 1.0x fits, so the fix must not move a single pixel there.
    // Compare against the pre-fix widget, copied verbatim below, rect by
    // rect: both buttons, both labels, both icons. Desktop is included
    // because its compact visual density lets a shrink-wrapping child
    // settle the button 8px narrower than on a phone.
    Future<List<Rect>> rects(
      WidgetTester tester,
      double width,
      bool legacy,
    ) async {
      await pumpAt(
        tester,
        locale: const Locale('ko'),
        width: width,
        textScale: 1.0,
        legacy: legacy,
      );
      Iterable<Rect> of(Type type) => find
          .byType(type)
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)));
      return [...of(ElevatedButton), ...of(Text), ...of(SvgPicture)];
    }

    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.macOS,
    ]) {
      for (final width in widths) {
        testWidgets(
          'ko ${width.toInt()}w 1.0x on ${platform.name} matches the old layout',
          (tester) async {
            debugDefaultTargetPlatformOverride = platform;
            addTearDown(() => debugDefaultTargetPlatformOverride = null);
            final before = await rects(tester, width, true);
            final after = await rects(tester, width, false);
            expect(after.length, before.length);
            expect(after.length, 6, reason: '2 buttons, 2 labels, 2 icons');
            for (var i = 0; i < after.length; i++) {
              for (final pair in [
                [after[i].left, before[i].left],
                [after[i].top, before[i].top],
                [after[i].width, before[i].width],
                [after[i].height, before[i].height],
              ]) {
                expect(
                  pair[0],
                  closeTo(pair[1], 0.01),
                  reason: 'rect $i moved: ${after[i]} vs ${before[i]}',
                );
              }
            }
            debugDefaultTargetPlatformOverride = null;
          },
        );
      }
    }
  });
}

/// ShareSection exactly as it was before PICNIC-2727, kept only as the
/// reference the geometry test compares against.
class _LegacyShareSection extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String saveButtonText;
  final String shareButtonText;

  const _LegacyShareSection({
    required this.onSave,
    required this.onShare,
    this.saveButtonText = 'save',
    this.shareButtonText = 'share',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shadowColor: AppColors.primary500,
              padding: EdgeInsets.zero,
              minimumSize: Size(120.w, 32),
              maximumSize: Size(120.w, 32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  saveButtonText,
                  style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/save_gallery.svg',
                  width: 16.w,
                  height: 16,
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          ElevatedButton(
            onPressed: onShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shadowColor: AppColors.primary500,
              padding: EdgeInsets.zero,
              minimumSize: Size(120.w, 32),
              maximumSize: Size(120.w, 32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shareButtonText,
                  style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                ),
                SizedBox(width: 8.w),
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/twitter_style=fill.svg',
                  width: 16.w,
                  height: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
