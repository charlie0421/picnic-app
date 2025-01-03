import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class UnderlinedWidget extends StatefulWidget {
  const UnderlinedWidget({
    super.key,
    required this.child,
    this.underlineColor,
    this.underlineHeight = 2,
    this.underlineGap = 4,
  });

  final Widget child;
  final Color? underlineColor;
  final double underlineHeight;
  final double underlineGap;

  @override
  State<UnderlinedWidget> createState() => _UnderlinedWidgetState();
}

class _UnderlinedWidgetState extends State<UnderlinedWidget> {
  final GlobalKey _widgetKey = GlobalKey();
  double? _width;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureWidth();
    });
  }

  void _measureWidth() {
    final RenderBox? box =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      setState(() {
        _width = box.size.width;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(key: _widgetKey, child: widget.child),
        if (_width != null)
          Positioned(
            bottom: -widget.underlineGap,
            left: 0,
            child: Container(
              width: _width,
              height: widget.underlineHeight,
              color: widget.underlineColor ?? AppColors.primary500,
            ),
          ),
      ],
    );
  }
}
