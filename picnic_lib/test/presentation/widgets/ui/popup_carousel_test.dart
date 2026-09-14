import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/l10n/app_localizations_th.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/popup_carousel.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

const double _compactWidth = 320;
const double _compactHeight = 568;

Popup _popup(int id) => Popup(
  id: id,
  title: {'ko': '팝업 제목 $id', 'en': 'Popup title $id'},
  content: {'ko': '팝업 본문 $id', 'en': 'Popup body $id'},
);

/// A popup whose copy is as long as the shipped Thai strings around it, so the
/// title and body compete with the actions for the same card budget.
Popup _thaiPopup(int id) => Popup(
  id: id,
  title: {
    'th': 'ประกาศสำคัญเกี่ยวกับการโหวตประจำสัปดาห์ $id',
    'en': 'Popup title $id',
  },
  content: {
    'th':
        'กรุณาอ่านรายละเอียดของกิจกรรมโหวตประจำสัปดาห์นี้ '
        'ก่อนเข้าร่วมเพื่อรับสิทธิประโยชน์ทั้งหมด $id',
    'en': 'Popup body $id',
  },
);

Finder _actionFor(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    )
    .first;

void main() {
  final l10n = AppLocalizationsKo();

  setUp(() {
    initTestColors();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpCarousel(WidgetTester tester, List<Popup> popups) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(suppressImageErrors());

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        const PopupCarousel(),
        extraOverrides: [popupProvider.overrideWith((ref) async => popups)],
      ),
    );
    // The provider future, then the hidden-popup filter future, each need a
    // frame of their own before the card is on screen.
    for (var frame = 0; frame < 5; frame += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    drainExpectedImageErrors(tester);
  }

  group('PopupCarousel presentation', () {
    testWidgets('both popup actions own a 48px tap target', (tester) async {
      await pumpCarousel(tester, [_popup(1)]);

      for (final label in [
        l10n.label_popup_close,
        l10n.label_popup_hide_7days,
      ]) {
        final action = _actionFor(label);
        expect(action, findsOneWidget, reason: label);
        expect(
          tester.getSize(action).height,
          greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
          reason: label,
        );
      }
    });

    testWidgets('the primary popup action paints the brand action colour', (
      tester,
    ) async {
      await pumpCarousel(tester, [_popup(1)]);

      final material = tester.widget<Material>(
        find
            .descendant(
              of: _actionFor(l10n.label_popup_hide_7days),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, PicnicUi.actionColor);
    });

    testWidgets('the popup body text uses the readable token style', (
      tester,
    ) async {
      await pumpCarousel(tester, [_popup(1)]);

      final body = tester.widget<Text>(find.text('팝업 본문 1'));
      expect(body.style?.height, 1.45);
      expect(body.style?.letterSpacing, 0);
    });

    testWidgets('the paging controls keep their 48px targets', (tester) async {
      await pumpCarousel(tester, [_popup(1), _popup(2)]);

      for (final icon in [Icons.chevron_left, Icons.chevron_right]) {
        final control = find
            .ancestor(of: find.byIcon(icon), matching: find.byType(InkWell))
            .first;
        expect(control, findsOneWidget);
        final size = tester.getSize(control);
        expect(size.height, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
        expect(size.width, greaterThanOrEqualTo(PicnicUi.minimumTapTarget));
      }
    });

    testWidgets('the Thai popup actions fit a 320px card at 200% text', (
      tester,
    ) async {
      // 320 logical minus the card's 48 outer margins leaves a 224 wide card,
      // and the 1:2 action row then has to hold the shipped Thai
      // "don't show for 7 days" label at 28px.
      final th = AppLocalizationsTh();
      tester.view.physicalSize = const Size(
        _compactWidth * 3,
        _compactHeight * 3,
      );
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      addTearDown(suppressImageErrors());

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const PopupCarousel(),
          locale: const Locale('th'),
          textScaler: const TextScaler.linear(2),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          extraOverrides: [
            popupProvider.overrideWith((ref) async => [_thaiPopup(1)]),
          ],
        ),
      );
      for (var frame = 0; frame < 5; frame += 1) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      drainExpectedImageErrors(tester);
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(Card));
      expect(card.top, greaterThanOrEqualTo(-0.5));
      expect(card.bottom, lessThanOrEqualTo(_compactHeight + 0.5));
      expect(card.left, greaterThanOrEqualTo(-0.5));
      expect(card.right, lessThanOrEqualTo(_compactWidth + 0.5));

      for (final label in [th.label_popup_close, th.label_popup_hide_7days]) {
        final action = _actionFor(label);
        expect(action, findsOneWidget, reason: label);
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(card.left - 0.5), reason: label);
        expect(rect.right, lessThanOrEqualTo(card.right + 0.5), reason: label);
        expect(
          rect.bottom,
          lessThanOrEqualTo(card.bottom + 0.5),
          reason: label,
        );
        expect(
          tester.getSize(action).height,
          greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
          reason: label,
        );
        // The label itself, not just the button box, has to be contained.
        final text = tester.getRect(find.text(label));
        expect(text.left, greaterThanOrEqualTo(rect.left - 0.5), reason: label);
        expect(text.right, lessThanOrEqualTo(rect.right + 0.5), reason: label);
        expect(
          text.bottom,
          lessThanOrEqualTo(rect.bottom + 0.5),
          reason: label,
        );
      }

      // The hero image keeps its shipped 16:9 ratio.
      final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspect.aspectRatio, 16 / 9);
    });

    testWidgets('closing the last popup hides the carousel', (tester) async {
      await pumpCarousel(tester, [_popup(1)]);

      await tester.tap(_actionFor(l10n.label_popup_close));
      await tester.pump();

      expect(find.text('팝업 제목 1'), findsNothing);
    });
  });
}
