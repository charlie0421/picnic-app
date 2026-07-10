import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

/// A one-shot tooltip: fades and slides in, holds for a beat, fades out, then
/// removes itself from the widget tree.
///
/// Removing itself matters. A bare [FadeTransition] would leave the
/// [IgnorePointer] sitting on top of the row at opacity 0 forever.
///
/// The widget owns its *animation*; the caller owns its *lifetime*. Nothing
/// here prevents a second instance from being built — the caller must ensure
/// it mounts this only once.
class VoteGapTooltip extends StatefulWidget {
  const VoteGapTooltip({super.key, required this.text, this.onDismissed});

  final String text;

  /// Called exactly once, when the fade-out completes.
  final VoidCallback? onDismissed;

  @override
  State<VoteGapTooltip> createState() => _VoteGapTooltipState();
}

class _VoteGapTooltipState extends State<VoteGapTooltip>
    with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 260);
  static const _hold = Duration(seconds: 1);

  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<Offset> _slide;
  Timer? _dismiss;
  bool _gone = false;
  // Guards the hold Timer so a re-entrant AnimationStatus.completed callback
  // (none in the current forward -> reverse -> dismissed lifecycle, but the
  // listener shouldn't assume that) can never stack a second Timer.
  bool _holdStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fade)..forward();
    // Build the curve once. Creating it in build() would stack a listener on
    // the controller every rebuild.
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(_curve);

    _controller.addStatusListener((status) {
      // The hold is measured from "fully opaque", not from mount, so start
      // it only once the fade-in has actually completed.
      if (status == AnimationStatus.completed && mounted && !_holdStarted) {
        _holdStarted = true;
        _dismiss = Timer(_hold, () {
          if (mounted) _controller.reverse();
        });
      } else if (status == AnimationStatus.dismissed && mounted && !_gone) {
        setState(() => _gone = true);
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();

    return IgnorePointer(
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: _slide,
          child: ConstrainedBox(
            // A Positioned child is unbounded; a long locale or a large gap
            // would otherwise run off the screen edge.
            constraints: const BoxConstraints(maxWidth: 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.grey900,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.text,
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: CustomPaint(
                    size: const Size(12, 6),
                    painter: _TailPainter(color: AppColors.grey900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
