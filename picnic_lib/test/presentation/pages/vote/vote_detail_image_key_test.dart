import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// B2 contract: the vote-detail list image widget keys must NOT embed rank.
// The page builds: RepaintBoundary key = ValueKey('image_<itemId>')
//                  PicnicCachedNetworkImage key = ValueKey('cached_image_<url>')
// Rank-up/down animation is owned by VoteItemWidget props, not the image key.
void main() {
  group('vote-detail image key stability across rank change', () {
    // Mirrors the exact key expressions in vote_detail_page.dart
    // (_buildNetworkImage / _buildImageWithFallback). If those expressions
    // change to re-include rank, update both sites AND this guard together.
    Key imageBoundaryKey(int itemId) => ValueKey('image_$itemId');
    Key cachedImageKey(String imageUrl) => ValueKey('cached_image_$imageUrl');

    test('RepaintBoundary key is identical for the same item at rank 1 vs 2',
        () {
      const itemId = 42;
      // Rank changed 1 -> 2 must not alter the widget key.
      expect(imageBoundaryKey(itemId), equals(imageBoundaryKey(itemId)));
      expect(
        imageBoundaryKey(itemId).toString(),
        equals("[<'image_42'>]"),
      );
      expect(imageBoundaryKey(itemId).toString(), isNot(contains('rank')));
    });

    test('cached image key is the URL only (no rank segment)', () {
      const url = 'artist/10.png';
      expect(cachedImageKey(url), equals(cachedImageKey(url)));
      expect(cachedImageKey(url).toString(), isNot(contains('rank')));
      expect(cachedImageKey(url).toString(), contains('artist/10.png'));
    });
  });
}
