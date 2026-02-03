import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';

class AttendanceDeadlineTimer extends StatefulWidget {
  final String deadlineUTC;
  final String label;
  final VoidCallback? onDeadlineReached;

  const AttendanceDeadlineTimer({
    super.key,
    required this.deadlineUTC,
    required this.label,
    this.onDeadlineReached,
  });

  @override
  State<AttendanceDeadlineTimer> createState() =>
      _AttendanceDeadlineTimerState();
}

class _AttendanceDeadlineTimerState extends State<AttendanceDeadlineTimer> {
  Timer? _timer;
  String _timeLeft = '';
  bool _deadlineCalled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(AttendanceDeadlineTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineUTC != widget.deadlineUTC) {
      _deadlineCalled = false;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final deadline = DateTime.parse(widget.deadlineUTC);
    final remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      setState(() => _timeLeft = '00:00:00');
      if (!_deadlineCalled) {
        _deadlineCalled = true;
        _timer?.cancel();
        widget.onDeadlineReached?.call();
      }
      return;
    }

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    setState(() => _timeLeft = '$hours:$minutes:$seconds');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: getTextStyle(AppTypo.caption10R, AppColors.grey400),
          ),
          SizedBox(width: 4.w),
        ],
        Icon(Icons.schedule, size: 12.w, color: AppColors.grey400),
        SizedBox(width: 3.w),
        Text(
          _timeLeft,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey500).copyWith(
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
