import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteGainIndicator extends StatefulWidget {
  final int diff;

  const VoteGainIndicator({super.key, required this.diff});

  @override
  State<VoteGainIndicator> createState() => _VoteGainIndicatorState();
}

class _VoteGainIndicatorState extends State<VoteGainIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  int? _displayDiff;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _displayDiff = null;
            });
          }
        });

    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.diff > 0) {
      _startAnimation(widget.diff);
    }
  }

  @override
  void didUpdateWidget(covariant VoteGainIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.diff > 0 && oldWidget.diff <= 0) {
      _startAnimation(widget.diff);
    }
  }

  void _startAnimation(int diff) {
    setState(() {
      _displayDiff = diff;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayDiff == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: child,
          ),
        );
      },
      child: Text(
        '+$_displayDiff',
        style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
      ),
    );
  }
}
