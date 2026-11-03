import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

/// A full-width or inline feedback block.
///
/// The adaptive layouts require a finite horizontal constraint. A screen or
/// card column naturally provides one; callers inside a [Row] must wrap this
/// widget in [Expanded], [Flexible], or a bounded box.
class PicnicFeedback extends StatelessWidget {
  const PicnicFeedback({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.inline = false,
    this.isLoading = false,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together.',
       );

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool inline;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'PicnicFeedback requires a bounded width. Wrap it in Expanded, '
          'Flexible, or a bounded box.',
        );
        if (!inline) return _buildFull();

        final scaledBodySize = MediaQuery.textScalerOf(context).scale(14);
        final shouldStack = constraints.maxWidth < 360 || scaledBodySize > 18.2;
        final messageContent = _buildMessage(textAlign: TextAlign.start);
        final action = _buildAction();

        if (action == null) return messageContent;
        if (shouldStack) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              messageContent,
              SizedBox(height: PicnicUi.vertical(8)),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: messageContent),
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

  Widget _buildFull() {
    final action = _buildAction();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMessage(textAlign: TextAlign.center),
        if (action != null) ...[
          SizedBox(height: PicnicUi.vertical(12)),
          Align(alignment: Alignment.center, child: action),
        ],
      ],
    );
  }

  Widget _buildMessage({required TextAlign textAlign}) {
    final text = Text(
      message,
      textAlign: textAlign,
      softWrap: true,
      style: PicnicUi.text(color: PicnicUi.secondaryText),
    );
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: PicnicUi.quietText),
        SizedBox(width: PicnicUi.horizontal(8)),
        Expanded(child: text),
      ],
    );
  }

  Widget? _buildAction() {
    if (actionLabel == null) return null;
    return PicnicActionButton(
      label: actionLabel!,
      onPressed: onAction,
      variant: PicnicActionVariant.secondary,
      isLoading: isLoading,
    );
  }
}
