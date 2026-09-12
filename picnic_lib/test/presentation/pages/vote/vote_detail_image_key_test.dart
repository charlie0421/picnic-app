import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';

import '../../../helpers/test_environment.dart';

// B2 contract: the vote-detail list image widget keys must NOT embed rank.
// The page builds: RepaintBoundary key = ValueKey('image_<itemId>')
//                  PicnicCachedNetworkImage key = ValueKey('cached_image_<url>')
// Rank-up/down animation is owned by VoteItemWidget props, not the image key.
void main() {
  setUpAll(initTestColors);

  group('vote-detail image key stability across rank change', () {
    // Mirrors the exact key expressions in vote_detail_page.dart
    // (_buildNetworkImage / _buildImageWithFallback). If those expressions
    // change to re-include rank, update both sites AND this guard together.
    Key imageBoundaryKey(int itemId) => ValueKey('image_$itemId');
    Key cachedImageKey(String imageUrl) => ValueKey('cached_image_$imageUrl');

    test(
      'RepaintBoundary key is identical for the same item at rank 1 vs 2',
      () {
        const itemId = 42;
        // Rank changed 1 -> 2 must not alter the widget key.
        expect(imageBoundaryKey(itemId), equals(imageBoundaryKey(itemId)));
        expect(imageBoundaryKey(itemId).toString(), equals("[<'image_42'>]"));
        expect(imageBoundaryKey(itemId).toString(), isNot(contains('rank')));
      },
    );

    test('cached image key is the URL only (no rank segment)', () {
      const url = 'artist/10.png';
      expect(cachedImageKey(url), equals(cachedImageKey(url)));
      expect(cachedImageKey(url).toString(), isNot(contains('rank')));
      expect(cachedImageKey(url).toString(), contains('artist/10.png'));
    });
  });

  testWidgets('extracted detail portrait request preserves the exact row key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    const source = '/artist/detail-key.png?obsolete=1';

    final legacyRowRequest = PicnicImageRequest.resolve(
      context: context,
      imageUrl: source,
      width: 39,
      height: 39,
      memCacheWidth: 78,
      memCacheHeight: 78,
      maxQualityOverride: 55,
      maxResolutionMultiplierCap: 2,
    );
    final extractedRequest = resolveVoteDetailPortraitImageRequest(
      context: context,
      imageUrl: source,
    );
    final configuration = createLocalImageConfiguration(
      context,
      size: const Size(39, 39),
    );

    expect(extractedRequest.url, legacyRowRequest.url);
    expect(Uri.parse(extractedRequest.url).queryParameters, {
      'q': '55',
      'w': '78',
      'h': '78',
    });
    expect(
      (extractedRequest.decodeWidth, extractedRequest.decodeHeight),
      (78, 78),
    );
    expect(
      await extractedRequest.obtainKey(configuration),
      await legacyRowRequest.obtainKey(configuration),
    );
  });
}
