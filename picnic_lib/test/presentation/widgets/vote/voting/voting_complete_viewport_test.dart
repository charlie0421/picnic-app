import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

// PICNIC-2699.
//
// The completion popup is stacked from fixed pixel heights and unbounded text,
// so it overflowed in both axes — 58px to the right even on a stock portrait
// phone at 1.0x, and up to 202px off the bottom on a landscape window. The
// existing voting_complete_test.dart silences overflow errors, which is why
// none of this was visible from the suite.
//
// It cannot be fixed by scrolling. This popup is captured as the shared vote
// image, and a scroll view only renders what is on screen, so the capture
// would lose whatever is scrolled away. Instead every box states a minimum
// rather than a fixed extent, and the whole card is scaled down as one piece
// when the window is shorter than it.
//
// The capture assertion below is the one that matters most: the shared image
// is a snapshot of the screen, so a popup that runs off the screen is cut in
// the shared image too, not merely on the display.
void main() {
  setUpAll(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  late VoteModel voteModel;
  late VoteItemModel voteItemModel;
  late Map<String, dynamic> result;

  setUp(() {
    setupMockSupabase(<String, dynamic>{});
    voteModel = MockData.vote(id: 1, titleKo: '테스트 투표');
    voteItemModel = MockData.voteItem(
      artist: MockData.artist(
        nameKo: '지민',
        artistGroup: MockData.artistGroup(nameKo: 'BTS'),
      ),
    );
    result = <String, dynamic>{
      'addedVoteTotal': 10,
      'votePickId': 'test-pick-id',
      'updatedAt': DateTime.utc(2026, 9, 16).toIso8601String(),
      'existingVoteTotal': 100,
      'updatedVoteTotal': 110,
    };
  });

  tearDown(tearDownMockSupabase);

  /// Pumps the popup and returns every overflow the frame reported.
  ///
  /// Asset and image-timeout noise is dropped because the test environment has
  /// no network; overflow is deliberately *not* dropped, which is the whole
  /// point of this file.
  Future<List<String>> pumpAt(
    WidgetTester tester, {
    required Size viewport,
    required double textScale,
  }) async {
    tester.view.physicalSize = Size(viewport.width * 3, viewport.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exception.toString();
      if (text.contains('overflowed')) {
        overflows.add(text.split('\n').first);
        return;
      }
      if (text.contains('LateInitializationError') ||
          text.contains('Unable to load asset') ||
          text.contains('Failed to load')) {
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(
      buildTestApp(
        VotingCompleteDialog(
          voteModel: voteModel,
          voteItemModel: voteItemModel,
          result: result,
        ),
        textScaler: TextScaler.linear(textScale),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return overflows;
  }

  /// Cancels the shimmer and image timers the popup leaves behind.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 31));
  }

  const viewports = <String, Size>{
    // The three the ticket names.
    'flip flex top half': Size(412, 500),
    'phone landscape': Size(851, 393),
    'tablet split third': Size(375, 834),
    // A stock phone, where the horizontal overflow lived, and the narrowest
    // and shortest windows the vote dialogs already support.
    'phone portrait': Size(393, 852),
    'iphone landscape': Size(844, 390),
    'narrow short window': Size(280, 480),
  };

  const textScales = <double>[1.0, 1.3, 2.0];

  group('PICNIC-2699 the completion popup fits the window it is given', () {
    for (final viewport in viewports.entries) {
      for (final textScale in textScales) {
        final label = '${viewport.key} ${textScale}x';

        testWidgets('$label lays out with nothing overflowing', (tester) async {
          final overflows = await pumpAt(
            tester,
            viewport: viewport.value,
            textScale: textScale,
          );
          expect(
            overflows,
            isEmpty,
            reason:
                '$label: an overflow here is content the user cannot see and '
                'that the shared image does not contain either.',
          );
          await settle(tester);
        });

        testWidgets('$label keeps the whole card on screen', (tester) async {
          await pumpAt(tester, viewport: viewport.value, textScale: textScale);
          final screen = Offset.zero & viewport.value;
          final card = tester.getRect(find.byType(LargePopupWidget));

          expect(
            card.left,
            greaterThanOrEqualTo(-0.5),
            reason: '$label: the card starts left of the window',
          );
          expect(
            card.top,
            greaterThanOrEqualTo(-0.5),
            reason: '$label: the card starts above the window',
          );
          expect(
            card.right,
            lessThanOrEqualTo(screen.right + 0.5),
            reason: '$label: the card runs past the right edge',
          );
          expect(
            card.bottom,
            lessThanOrEqualTo(screen.bottom + 0.5),
            reason: '$label: the card runs past the bottom edge',
          );
          await settle(tester);
        });

        testWidgets('$label keeps save and share reachable', (tester) async {
          await pumpAt(tester, viewport: viewport.value, textScale: textScale);
          final share = find.byType(ShareSection);
          expect(share, findsOneWidget, reason: label);

          final rect = tester.getRect(share);
          final screen = Offset.zero & viewport.value;
          expect(
            screen.contains(rect.topLeft) &&
                screen.contains(rect.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason:
                '$label: the save/share row sits outside the window at '
                '$rect. Scaling the card down is only worth anything if the '
                'controls come with it.',
          );
          // The row's own centre falls in the gap between the two buttons,
          // so aim at the buttons themselves.
          expect(
            find
                .descendant(of: share, matching: find.byType(ElevatedButton))
                .hitTestable(),
            findsNWidgets(2),
            reason:
                '$label: save and share do not answer a hit test where they '
                'are drawn. A scaled card that cannot be tapped is worse '
                'than one that is clipped.',
          );
          await settle(tester);
        });

        testWidgets('$label captures the card it displays', (tester) async {
          await pumpAt(tester, viewport: viewport.value, textScale: textScale);

          // The share and save paths both capture this boundary. It covers the
          // window, so whatever leaves the window leaves the image.
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find
                .descendant(
                  of: find.byType(VotingCompleteDialog),
                  matching: find.byType(RepaintBoundary),
                )
                .first,
          );
          final captured = boundary.localToGlobal(Offset.zero) & boundary.size;
          final card = tester.getRect(find.byType(LargePopupWidget));

          expect(
            captured.contains(card.topLeft) &&
                captured.contains(card.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason:
                '$label: the card at $card is not inside the captured area '
                '$captured, so the shared vote image is cut.',
          );
          await settle(tester);
        });
      }
    }
  });

  group('PICNIC-2699 scaling only ever shrinks', () {
    testWidgets('a roomy portrait window renders the card at design size', (
      tester,
    ) async {
      await pumpAt(tester, viewport: const Size(393, 852), textScale: 1.0);
      // getRect carries the scale; getSize would report the pre-scale layout
      // size and pass no matter what BoxFit did.
      expect(
        tester.getRect(find.byType(LargePopupWidget)).width,
        closeTo(defaultLargePopupWidth(), 0.5),
        reason:
            'A window with room to spare must look exactly as it did before '
            'PICNIC-2699. BoxFit.scaleDown never enlarges, and it must not '
            'shrink here either.',
      );
      await settle(tester);
    });

    testWidgets('a short window renders the same card smaller', (tester) async {
      await pumpAt(tester, viewport: const Size(851, 393), textScale: 1.0);
      expect(
        tester.getRect(find.byType(LargePopupWidget)).width,
        lessThan(defaultLargePopupWidth() - 0.5),
        reason:
            'A window shorter than the card has to scale it down. If this '
            'passes at full size the card is being clipped instead.',
      );
      await settle(tester);
    });
  });

  group('PICNIC-2699 follow-up: data the popup does not control', () {
    // A group-only item whose group has no image. ArtistGroupModel.image is
    // nullable and the artist branch already tolerates a missing URL; the
    // group branch force-unwrapped it and threw.
    testWidgets('a group with no image still renders', (tester) async {
      voteItemModel = VoteItemModel.fromJson(<String, dynamic>{
        'id': 1,
        'vote_total': 1,
        'vote_id': 1,
        'artist': null,
        'artist_group': <String, dynamic>{
          'id': 22,
          'name': <String, dynamic>{'ko': '그룹'},
          'image': null,
        },
      });
      final overflows = await pumpAt(
        tester,
        viewport: const Size(851, 393),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(overflows, isEmpty);
      expect(find.byType(LargePopupWidget), findsOneWidget);
      await settle(tester);
    });

    // Names come from the server and have no length limit. The popup scales
    // to fit its natural height, so an unbounded name used to shrink the
    // whole card with it: a 96-character name at 2.0x on a 280x480 window
    // drew the save button's tap target at about 14x8 px. With the name lines
    // capped, the name must not move the scale at all — a long name has to
    // produce exactly the card a short one does.
    Future<Rect> saveButtonRect(WidgetTester tester) async {
      final overflows = await pumpAt(
        tester,
        viewport: const Size(280, 480),
        textScale: 2.0,
      );
      expect(overflows, isEmpty);
      return tester.getRect(
        find
            .descendant(
              of: find.byType(ShareSection),
              matching: find.byType(ElevatedButton),
            )
            .first,
      );
    }

    for (final length in const [20, 96, 384]) {
      testWidgets('a $length-character name does not shrink the card', (
        tester,
      ) async {
        voteItemModel = MockData.voteItem(
          artist: MockData.artist(artistGroup: MockData.artistGroup()),
        );
        final baseline = await saveButtonRect(tester);

        voteItemModel = MockData.voteItem(
          artist: MockData.artist(
            nameKo: 'W' * length,
            nameEn: 'W' * length,
            artistGroup: MockData.artistGroup(
              nameKo: 'G' * length,
              nameEn: 'G' * length,
            ),
          ),
        );
        final long = await saveButtonRect(tester);

        expect(
          long.size.width,
          closeTo(baseline.size.width, 0.5),
          reason:
              'length $length: the save button is ${long.size} against '
              '${baseline.size} for a short name. A name must not be able to '
              'scale the controls down.',
        );
        expect(long.size.height, closeTo(baseline.size.height, 0.5));
        await settle(tester);
      });
    }
  });
}
