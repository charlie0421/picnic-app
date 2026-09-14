import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

class PicnicFilterChip extends StatelessWidget {
  const PicnicFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? AppColors.primary500 : PicnicUi.surface;
    final foregroundColor = selected
        ? PicnicUi.primaryForeground
        : PicnicUi.ink;
    final borderColor = selected ? PicnicUi.actionColor : PicnicUi.border;
    final borderRadius = BorderRadius.circular(999);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: borderColor),
    );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onSelected != null,
      label: label,
      onTap: onSelected,
      excludeSemantics: true,
      child: Material(
        color: backgroundColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          excludeFromSemantics: true,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: PicnicUi.minimumTapTarget,
              minHeight: PicnicUi.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PicnicUi.horizontal(16),
                vertical: PicnicUi.vertical(8),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: PicnicUi.text(
                    weight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
