import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

/// Pure-logic helpers extracted from [VoteInfoCard] for testability.
class VoteInfoCardHelper {
  const VoteInfoCardHelper._();

  /// Sorts vote items by [voteTotal] descending and truncates to top 3
  /// for active/end statuses. For upcoming status, returns all items sorted.
  static List<VoteItemModel> prepareVoteItems(
    List<VoteItemModel>? rawItems,
    VoteStatus status,
  ) {
    final items = List<VoteItemModel>.from(rawItems ?? <VoteItemModel>[]);
    items.sort((a, b) => (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0));
    if (status == VoteStatus.upcoming) {
      return items;
    }
    return items.length <= 3 ? items : items.take(3).toList();
  }

  /// Returns the same top three ranked items rendered by an active/end card.
  /// Non-rank statuses retain the shared two-candidate default.
  static List<VoteItemModel> previewItems(
    List<VoteItemModel>? items,
    VoteStatus status,
  ) {
    final maximumCandidates =
        status == VoteStatus.active || status == VoteStatus.end ? 3 : 2;
    return prepareVoteItems(items, status).take(maximumCandidates).toList();
  }

  /// Builds the exact request shared by rank display and adjacent-card
  /// prefetch. The visible portrait slot is 72 logical pixels square.
  static PicnicImageRequest rankImageRequest(
    BuildContext context,
    VoteItemModel item,
  ) {
    return PicnicImageRequest.resolve(
      context: context,
      imageUrl: resolveVoteItemImageUrl(item),
      width: 72,
      height: 72,
    );
  }

  /// Builds the exact request shared by an upcoming thumbnail and its next
  /// internal page prefetch.
  static PicnicImageRequest thumbnailImageRequest(
    BuildContext context,
    VoteItemModel item,
  ) {
    return PicnicImageRequest.resolve(
      context: context,
      imageUrl: resolveVoteItemImageUrl(item),
      width: 56,
      height: 56,
    );
  }

  /// Splits a list of items into pages of [pageSize] items each.
  static List<List<T>> paginateItems<T>(List<T> items, int pageSize) {
    final List<List<T>> pages = [];
    for (int i = 0; i < items.length; i += pageSize) {
      pages.add(items.sublist(i, math.min(i + pageSize, items.length)));
    }
    return pages;
  }

  /// Pads a list to [targetLength] with nulls if needed.
  static List<T?> padWithNulls<T>(List<T> items, int targetLength) {
    final paddedItems = <T?>[...items.take(targetLength)];
    while (paddedItems.length < targetLength) {
      paddedItems.add(null);
    }
    return paddedItems;
  }

  /// Resolves the display image URL from a vote item, preferring
  /// artist image when artist.id != 0, otherwise using artistGroup image.
  static String resolveVoteItemImageUrl(VoteItemModel item) {
    return ((item.artist?.id != 0)
            ? item.artist?.image
            : item.artistGroup?.image) ??
        '';
  }
}
