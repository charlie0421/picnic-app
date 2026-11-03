import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

enum PicnicActionVariant { primary, secondary }

class PicnicActionButton extends StatelessWidget {
  const PicnicActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PicnicActionVariant.primary,
    this.isLoading = false,
    this.busySemanticLabel,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PicnicActionVariant variant;
  final bool isLoading;
  final String? busySemanticLabel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final callback = enabled ? onPressed : null;
    final activeForeground = variant == PicnicActionVariant.primary
        ? PicnicUi.onActionColor
        : PicnicUi.actionColor;
    final foreground = enabled || isLoading
        ? activeForeground
        : PicnicUi.secondaryText;
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: isLoading ? 0 : 1,
          child: _ButtonContent(label: label, icon: icon, color: foreground),
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(child: SmallPulseLoadingIndicator()),
          ),
      ],
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: isLoading ? (busySemanticLabel ?? label) : label,
      liveRegion: isLoading,
      onTap: callback,
      excludeSemantics: true,
      child: variant == PicnicActionVariant.primary
          ? FilledButton(
              onPressed: callback,
              style: FilledButton.styleFrom(
                foregroundColor: activeForeground,
                backgroundColor: PicnicUi.actionColor,
                disabledForegroundColor: foreground,
                disabledBackgroundColor: isLoading
                    ? PicnicUi.actionColor
                    : PicnicUi.disabledSurface,
                minimumSize: const Size.square(PicnicUi.minimumTapTarget),
                padding: EdgeInsets.symmetric(
                  horizontal: PicnicUi.horizontal(16),
                  vertical: PicnicUi.vertical(12),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: callback,
              style: OutlinedButton.styleFrom(
                foregroundColor: activeForeground,
                backgroundColor: PicnicUi.surface,
                disabledForegroundColor: foreground,
                disabledBackgroundColor: PicnicUi.surface,
                minimumSize: const Size.square(PicnicUi.minimumTapTarget),
                padding: EdgeInsets.symmetric(
                  horizontal: PicnicUi.horizontal(16),
                  vertical: PicnicUi.vertical(12),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: enabled || isLoading
                      ? PicnicUi.actionColor
                      : PicnicUi.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: content,
            ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final Widget? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      style: PicnicUi.text(size: 14, weight: FontWeight.w600, color: color),
    );
    if (icon == null) return labelText;

    return IconTheme.merge(
      data: IconThemeData(color: color, size: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: PicnicUi.horizontal(8),
        runSpacing: PicnicUi.vertical(4),
        children: [icon!, labelText],
      ),
    );
  }
}
