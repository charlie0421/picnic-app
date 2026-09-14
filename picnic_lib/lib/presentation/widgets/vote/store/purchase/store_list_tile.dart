import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

class StoreListTile extends StatelessWidget {
  const StoreListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.buttonOnPressed,
    this.isLoading = false,
    this.index,
    this.buttonScale,
    this.badge,
    this.isPromoted = false,
    this.flexibleHeight = false,
    this.actionMinWidth,
  });

  final Image icon;
  final Text title;
  final Widget? subtitle;
  final String buttonText;
  final VoidCallback? buttonOnPressed;
  final bool isLoading;
  final int? index;
  final double? buttonScale;
  final Widget? badge;
  final bool isPromoted;
  final bool flexibleHeight;

  /// A shared width for the action so sibling tiles line up.
  ///
  /// PICNIC-2687: each price button used to hug its own label, so a column of
  /// "₩9,900" … "₩110,000" looked jagged. A list passes
  /// [uniformActionWidth] of every label it shows; the label is centered in
  /// the wider box. Null keeps the button at its natural width.
  final double? actionMinWidth;

  /// The natural width of the action button for the widest of [labels],
  /// measured with the same style and text scale the button renders with.
  static double uniformActionWidth(
    BuildContext context,
    Iterable<String> labels,
  ) {
    var width = 0.0;
    for (final label in labels) {
      width = math.max(width, _naturalActionWidth(context, label));
    }
    return width;
  }

  static double _naturalActionWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: PicnicUi.text(size: 14, weight: FontWeight.w600),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = (painter.width + PicnicUi.horizontal(32)).clamp(
      PicnicUi.minimumTapTarget,
      double.infinity,
    );
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (flexibleHeight)
          Wrap(
            spacing: PicnicUi.horizontal(8),
            runSpacing: PicnicUi.vertical(4),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              title,
              if (badge != null)
                KeyedSubtree(
                  key: const Key('candy-boost-inline-badge'),
                  child: badge!,
                ),
            ],
          )
        else
          Row(
            children: [
              Flexible(child: title),
              if (badge != null) ...[
                SizedBox(width: PicnicUi.horizontal(8)),
                Flexible(child: badge!),
              ],
            ],
          ),
        if (subtitle != null) ...[
          SizedBox(height: PicnicUi.vertical(4)),
          subtitle!,
        ],
      ],
    );
    final naturalPriceWidth = _naturalActionWidth(context, buttonText);
    // Never narrower than this label needs: a shared width only widens.
    final priceWidth = math.max(naturalPriceWidth, actionMinWidth ?? 0);
    final button = PicnicActionButton(
      key: const Key('purchase-price-cta'),
      label: buttonText,
      onPressed: buttonOnPressed,
      isLoading: isLoading,
      busySemanticLabel: AppLocalizations.of(context).loading,
    );
    final action = actionMinWidth == null
        ? button
        : SizedBox(width: priceWidth, child: button);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: subtitle != null ? 64 : 48),
      child: SizedBox(
        width: buttonScale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final iconWidth = icon.width ?? 48.w;
            final leadingGap = PicnicUi.horizontal(16);
            final actionGap = PicnicUi.horizontal(8);
            // Preserve a useful text column. Long prices and larger text put
            // the action below the product instead of shrinking either label.
            final stackAction =
                constraints.hasBoundedWidth &&
                constraints.maxWidth <
                    iconWidth +
                        leadingGap +
                        scaler.scale(128) +
                        actionGap +
                        priceWidth;
            if (stackAction) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      icon,
                      SizedBox(width: leadingGap),
                      Expanded(child: details),
                    ],
                  ),
                  SizedBox(height: PicnicUi.vertical(8)),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                icon,
                SizedBox(width: leadingGap),
                Expanded(child: details),
                SizedBox(width: actionGap),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}
