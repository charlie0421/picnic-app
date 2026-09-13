import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

/// Shared geometry for the vote card and its loading placeholder.
abstract final class VoteCardLayout {
  static const double thumbnailSize = 56;
  static const double thumbnailLabelGap = 4;
  static const double thumbnailRowSpacing = 4;
  static const double thumbnailColumnSpacing = 8;
  static const int thumbnailColumns = 4;
  static const int maximumThumbnailRows = 3;
  static const double thumbnailPagerHeight = 48;

  static double shareSectionExtent(BuildContext context) {
    final theme = Theme.of(context);
    final tapHeight =
        theme.materialTapTargetSize == MaterialTapTargetSize.padded
        ? kMinInteractiveDimension + theme.visualDensity.baseSizeAdjustment.dy
        : 32.0;
    return 16 + tapHeight.clamp(32, double.infinity);
  }

  static double textHeight(
    BuildContext context,
    String text,
    TextStyle style, {
    required double maxWidth,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static double thumbnailTileExtent(BuildContext context) {
    final labelHeight = textHeight(
      context,
      '가Ag',
      getTextStyle(AppTypo.caption10SB, AppColors.grey900),
      maxWidth: thumbnailSize,
    );
    return thumbnailSize + thumbnailLabelGap + labelHeight;
  }

  static double thumbnailGridExtent(BuildContext context, int rows) {
    final safeRows = rows.clamp(1, maximumThumbnailRows);
    return thumbnailTileExtent(context) * safeRows +
        thumbnailRowSpacing * (safeRows - 1);
  }

  static int thumbnailRowsForHeight(
    BuildContext context,
    double availableHeight,
  ) {
    if (!availableHeight.isFinite) return maximumThumbnailRows;

    final tileExtent = thumbnailTileExtent(context);
    final rows =
        ((availableHeight + thumbnailRowSpacing) /
                (tileExtent + thumbnailRowSpacing))
            .floor();
    return rows.clamp(1, maximumThumbnailRows);
  }
}
