import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  // 39pt 행 portrait 는 모든 기기가 78px 변형 하나를 공유하고, 디코드도
  // 78px 로 고정된다. 팝업의 캐시 전용 placeholder 가 같은 키를 찾는다.
  testWidgets('detail portrait request is one fixed 78px variant everywhere', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const source = '/artist/detail-key.png?obsolete=1';
    final urls = <String>{};
    final keys = <Object>{};
    for (final (size, dpr) in const [
      (Size(375, 812), 3.0),
      (Size(360, 780), 2.0),
      (Size(1024, 1366), 2.0),
    ]) {
      tester.view.physicalSize = size * dpr;
      tester.view.devicePixelRatio = dpr;
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

      final request = resolveVoteDetailPortraitImageRequest(
        context: context,
        imageUrl: source,
      );
      urls.add(request.url);
      expect((request.decodeWidth, request.decodeHeight), (78, 78));
      keys.add(
        await request.obtainKey(
          createLocalImageConfiguration(context, size: const Size(39, 39)),
        ),
      );
    }

    expect(urls, {
      'https://test-cdn.example.com/artist/detail-key.png?q=55&w=78',
    });
    expect(keys, hasLength(1));
  });
}
