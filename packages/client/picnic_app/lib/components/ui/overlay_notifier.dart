import 'package:flutter/material.dart';
import 'package:picnic_app/app.dart';

class OverlayNotification extends StatefulWidget {
  final Widget Function(int remainingSeconds) childBuilder;
  final Duration duration;
  final VoidCallback? onDismiss;

  const OverlayNotification({
    Key? key,
    required this.childBuilder,
    this.duration = const Duration(seconds: 5),
    this.onDismiss,
  }) : super(key: key);

  @override
  _OverlayNotificationState createState() => _OverlayNotificationState();
}

class _OverlayNotificationState extends State<OverlayNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();

    _remainingSeconds = widget.duration.inSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _dismiss();
        return false;
      }
      return true;
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: widget.childBuilder(_remainingSeconds),
        ),
      ),
    );
  }
}

OverlayEntry? _lastEntry;

extension OverlayNotifierContext on BuildContext {
  void showOverlayNotification({
    required Widget Function(int remainingSeconds) childBuilder,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showOverlay(
      OverlayNotification(
        duration: duration,
        childBuilder: childBuilder,
        onDismiss: _removeOverlay,
      ),
    );
  }

  void _showOverlay(Widget overlay) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    final entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          Positioned(top: 0, left: 0, right: 0, child: overlay),
        ],
      ),
    );

    _lastEntry = entry;
    overlayState.insert(entry);
  }

  void _removeOverlay() {
    _lastEntry?.remove();
    _lastEntry = null;
  }
}
