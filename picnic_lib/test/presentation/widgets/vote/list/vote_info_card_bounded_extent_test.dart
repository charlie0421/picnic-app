import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
const _galleryChannel = MethodChannel('image_gallery_saver_plus');

int _pngHeight(Uint8List bytes) {
  // PNG IHDR stores its big-endian height at bytes 20-23.
  return ByteData.sublistView(bytes, 20, 24).getUint32(0, Endian.big);
}

VoteModel _upcomingVote() {
  return VoteFactory.create(
    title: const {'ko': '후보 페이지를 유지하는 예정 투표'},
    isUpcoming: true,
    startAt: DateTime.now().add(const Duration(days: 1)),
    voteItem: List.generate(
      24,
      (index) => VoteItemFactory.create(
        id: index + 1,
        artist: ArtistModel(id: index + 1, name: {'ko': '후보${index + 1}'}),
      ),
    ),
  );
}

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });
  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
  });

  for (final status in [VoteStatus.active, VoteStatus.end]) {
    testWidgets(
      '$status keeps rank and capture height when the page has extra space',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final vote = VoteFactory.create(
          title: const {'ko': '생일 축하 아티스트 투표'},
          isEnded: status == VoteStatus.end,
          voteItem: List.generate(
            3,
            (index) => VoteItemFactory.create(
              id: index + 1,
              artist: ArtistModel(
                id: index + 1,
                name: {'ko': '후보${index + 1}'},
              ),
            ),
          ),
        );

        Future<({double bodyHeight, double captureHeight})> measure(
          bool bounded,
        ) async {
          final card = Builder(
            builder: (context) =>
                VoteInfoCard(context: context, vote: vote, status: status),
          );
          await pumpWidgetAndIgnoreErrors(
            tester,
            buildTestApp(
              bounded
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(height: 600, child: card),
                    )
                  : SingleChildScrollView(child: card),
              designSize: kAppDesignSize,
              splitScreenMode: kAppSplitScreenMode,
              mediaQueryData: const MediaQueryData(size: Size(390, 844)),
            ),
          );
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
          final bodyHeight =
              tester.getTopLeft(find.byType(ShareSection)).dy -
              tester.getBottomLeft(find.byType(VoteCardInfoHeader)).dy;
          final capture = find
              .descendant(
                of: find.byType(VoteInfoCard),
                matching: find.byType(RepaintBoundary),
              )
              .first;
          final captureHeight = tester.getSize(capture).height;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
          return (bodyHeight: bodyHeight, captureHeight: captureHeight);
        }

        final natural = await measure(false);
        final bounded = await measure(true);
        expect(
          bounded.bodyHeight,
          closeTo(natural.bodyHeight, 0.5),
          reason: 'A tall vote page must not stretch the existing rank area',
        );
        expect(
          bounded.captureHeight,
          closeTo(natural.captureHeight, 0.5),
          reason: 'Saved images must not acquire unused page space',
        );
      },
    );
  }

  testWidgets(
    'gallery save captures only the card body and keeps the candidate page stable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      final tempDirectory = Directory.systemTemp.createTempSync(
        'vote-card-save-test-',
      );
      Uint8List? savedBytes;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async {
        return call.method == 'getTemporaryDirectory'
            ? tempDirectory.path
            : null;
      });
      messenger.setMockMethodCallHandler(_galleryChannel, (call) async {
        if (call.method == 'saveImageToGallery') {
          final arguments = call.arguments as Map<Object?, Object?>;
          savedBytes = arguments['imageBytes'] as Uint8List;
        }
        return <String, Object?>{'isSuccess': true};
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(_pathProviderChannel, null);
        messenger.setMockMethodCallHandler(_galleryChannel, null);
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 600,
              child: Builder(
                builder: (context) => VoteInfoCard(
                  context: context,
                  vote: _upcomingVote(),
                  status: VoteStatus.upcoming,
                ),
              ),
            ),
          ),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          mediaQueryData: const MediaQueryData(size: Size(390, 844)),
        ),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      final candidatePager = find.byWidgetPredicate(
        (widget) =>
            widget is PageView && widget.scrollDirection == Axis.horizontal,
      );
      final candidatePageView = tester.widget<PageView>(candidatePager);
      expect(
        candidatePageView.childrenDelegate.estimatedChildCount,
        greaterThan(1),
      );
      candidatePageView.controller!.jumpToPage(1);
      await pumpAndIgnoreErrors(tester);
      expect(
        tester.widget<PageView>(candidatePager).controller!.page,
        closeTo(1, 0.01),
      );

      final bodyCaptureHeights = find
          .ancestor(
            of: find.byType(VoteCardInfoHeader),
            matching: find.byType(RepaintBoundary),
          )
          .evaluate()
          .map(
            (element) =>
                (element.renderObject! as RenderRepaintBoundary).size.height,
          )
          .where((height) => height > 0)
          .toList();
      expect(bodyCaptureHeights, isNotEmpty);
      final bodyCaptureHeight = bodyCaptureHeights.reduce(
        (smallest, height) => height < smallest ? height : smallest,
      );
      final candidateBoundsBeforeSave = tester.getRect(candidatePager);
      final actionsBoundsBeforeSave = tester.getRect(find.byType(ShareSection));
      final candidatePageBeforeSave = tester
          .widget<PageView>(candidatePager)
          .controller!
          .page!;

      await tester.tap(find.text('저장'));
      await tester.pump();

      final actionsVisibility = tester.widget<Visibility>(
        find
            .ancestor(
              of: find.byType(ShareSection),
              matching: find.byType(Visibility),
            )
            .first,
      );
      expect(actionsVisibility.visible, isFalse);
      expect(tester.getRect(candidatePager), candidateBoundsBeforeSave);
      expect(
        tester.getRect(find.byType(ShareSection)),
        actionsBoundsBeforeSave,
      );
      expect(
        tester.widget<PageView>(candidatePager).controller!.page,
        closeTo(candidatePageBeforeSave, 0.01),
      );

      for (var attempt = 0; attempt < 20 && savedBytes == null; attempt++) {
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }

      expect(savedBytes, isNotNull, reason: 'The real save callback must run');
      final savedLogicalHeight = _pngHeight(savedBytes!) / 2;
      expect(
        savedLogicalHeight,
        closeTo(bodyCaptureHeight, 1),
        reason: 'The gallery PNG must exclude the maintained action strip',
      );

      drainExpectedImageErrors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
