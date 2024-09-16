import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoteStatus status;
  final VoidCallback? onRefresh;
  const CountdownTimer(
      {super.key, required this.endTime, required this.status, this.onRefresh});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  Color _color = AppColors.mint500;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = widget.endTime.difference(DateTime.now().toUtc());
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
    }
    _updateColor();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.endTime.difference(DateTime.now().toUtc());
        if (_timeLeft.isNegative) {
          _timeLeft = Duration.zero;
          _timer?.cancel();
        }
        _updateColor();
        // widget.onRefresh?.call();
      });
    });
  }

  void _updateColor() {
    if (_timeLeft.inHours > 24) {
      _color = AppColors.mint500;
    } else if (_timeLeft.inHours > 1) {
      _color = AppColors.sub500;
    } else if (_timeLeft.inMinutes > 0) {
      _color = AppColors.point500;
    } else {
      _color = AppColors.grey300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Column(
      children: [
        if (widget.status == VoteStatus.upcoming)
          Container(
            height: 20,
            alignment: Alignment.center,
            child: Text(S.of(context).label_vote_upcoming,
                style: getTextStyle(AppTypo.caption12B, _color)),
          ),
        if (widget.status == VoteStatus.end)
          Text(S.of(context).label_vote_end,
              style: getTextStyle(AppTypo.caption12B, AppColors.grey300)),
        if (widget.status != VoteStatus.end)
          SizedBox(
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ..._buildTimeUnit(totalDays, 'D'),
                ..._buildTimeUnit(hours),
                Text(' : ',
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey900)),
                ..._buildTimeUnit(minutes),
                Text(' : ',
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey900)),
                ..._buildTimeUnit(seconds),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTimeUnit(int value, [String? unit]) {
    final digits = value.toString().padLeft(2, '0');
    return [
      ...List.generate(digits.length, (index) {
        return _buildTimeCircle(digits[index]);
      }),
      if (unit != null)
        Text(' $unit ',
            style: getTextStyle(AppTypo.caption12M, AppColors.grey900)),
    ];
  }

  Widget _buildTimeCircle(String time) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      // padding: EdgeInsets.symmetric(horizontal: 5.cw),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(time,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey900)),
    );
  }
}
