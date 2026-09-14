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
    final action = PicnicActionButton(
      key: const Key('purchase-price-cta'),
      label: buttonText,
      onPressed: buttonOnPressed,
      isLoading: isLoading,
      busySemanticLabel: AppLocalizations.of(context).loading,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: subtitle != null ? 64 : 48),
      child: SizedBox(
        width: buttonScale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final pricePainter = TextPainter(
              text: TextSpan(
                text: buttonText,
                style: PicnicUi.text(size: 14, weight: FontWeight.w600),
              ),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            final priceWidth = (pricePainter.width + PicnicUi.horizontal(32))
                .clamp(48.0, double.infinity);
            pricePainter.dispose();
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
