import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

/// A section title with an optional adaptive action.
///
/// When an action is present this widget requires a finite horizontal
/// constraint. Callers inside a [Row] must provide one with [Expanded],
/// [Flexible], or a bounded box.
class PicnicSectionHeader extends StatelessWidget {
  const PicnicSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together.',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      softWrap: true,
      style: PicnicUi.text(size: 18, weight: FontWeight.w600),
    );
    if (actionLabel == null) return titleText;

    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'PicnicSectionHeader requires a bounded width. Wrap it in Expanded, '
          'Flexible, or a bounded box.',
        );
        final scaledTitleSize = MediaQuery.textScalerOf(context).scale(18);
        final shouldStack =
            constraints.maxWidth < 360 || scaledTitleSize > 23.4;
        final actionColor = PicnicUi.actionColor;
        final action = TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: actionColor,
            minimumSize: const Size.square(PicnicUi.minimumTapTarget),
            padding: EdgeInsets.symmetric(
              horizontal: PicnicUi.horizontal(8),
              vertical: PicnicUi.vertical(8),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel!,
            textAlign: TextAlign.center,
            softWrap: true,
            style: PicnicUi.text(weight: FontWeight.w600, color: actionColor),
          ),
        );

        if (shouldStack) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleText,
              SizedBox(height: PicnicUi.vertical(4)),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleText),
            SizedBox(width: PicnicUi.horizontal(12)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: action,
            ),
          ],
        );
      },
    );
  }
}
