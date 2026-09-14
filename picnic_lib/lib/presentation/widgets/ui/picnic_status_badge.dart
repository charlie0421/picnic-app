import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

class PicnicStatusBadge extends StatelessWidget {
  const PicnicStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  final String label;
  final Color backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedForeground =
        foregroundColor ?? PicnicUi.foregroundFor(backgroundColor);

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: PicnicUi.horizontal(8),
                vertical: PicnicUi.vertical(4),
              ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: PicnicUi.text(
              size: 12,
              weight: FontWeight.w600,
              color: resolvedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
