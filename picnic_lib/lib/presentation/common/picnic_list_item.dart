import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

class PicnicListItem extends StatelessWidget {
  final String leading;
  final String assetPath;
  final VoidCallback? onTap;
  final Widget? tailing;
  final Widget? title;

  const PicnicListItem({
    super.key,
    required this.leading,
    required this.assetPath,
    this.onTap,
    this.tailing,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      leading,
      style: PicnicUi.text(size: 16, weight: FontWeight.w500),
    );
    final trailing =
        tailing ??
        SvgPicture.asset(
          package: 'picnic_lib',
          assetPath,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(PicnicUi.ink, BlendMode.srcIn),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 61),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: PicnicUi.vertical(12)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      title != null &&
                      (constraints.maxWidth < 320 ||
                          MediaQuery.textScalerOf(context).scale(16) > 20.8);
                  return Row(
                    children: [
                      if (stacked)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              SizedBox(height: PicnicUi.vertical(4)),
                              title!,
                            ],
                          ),
                        )
                      else if (title == null)
                        Expanded(child: label)
                      else ...[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.45,
                          ),
                          child: label,
                        ),
                        SizedBox(width: PicnicUi.horizontal(8)),
                        Expanded(child: title!),
                      ],
                      SizedBox(width: PicnicUi.horizontal(8)),
                      trailing,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Divider(color: PicnicUi.border),
      ],
    );
  }
}
