import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

/// An opaque framed surface that deliberately does not clip its child.
///
/// Image and filled-header callers own their clipping so adopting this
/// presentation primitive never changes paint behavior implicitly.
class PicnicSurface extends StatelessWidget {
  const PicnicSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: PicnicUi.surfaceDecoration(radius: radius, color: color),
      child: child,
    );
  }
}
