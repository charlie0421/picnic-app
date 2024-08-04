import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoteStatus status;

  const CountdownTimer(
      {super.key, required this.endTime, required this.status});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  Color _color = AppColors.Mint500;

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
      });
    });
  }

  void _updateColor() {
    if (_timeLeft.inHours > 24) {
      _color = AppColors.Mint500;
    } else if (_timeLeft.inHours > 1) {
      _color = AppColors.Sub500;
    } else if (_timeLeft.inMinutes > 0) {
      _color = AppColors.Point500;
    } else {
      _color = AppColors.Grey300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays.remainder(24).toString().padLeft(2, '0');
    final hours = _timeLeft.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes =
        _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      children: [
        if (widget.status == VoteStatus.upcoming)
          Container(
            height: 20,
            alignment: Alignment.center,
            child: Text(S.of(context).label_vote_upcoming,
                style: getTextStyle(AppTypo.CAPTION12B, _color)),
          ),
        SizedBox(
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ..._buildDoubleDigits(days),
              Text(' D ',
                  style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey900)),
              ..._buildDoubleDigits(hours),
              Text(' : ',
                  style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey900)),
              ..._buildDoubleDigits(minutes),
              Text(' : ',
                  style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey900)),
              ..._buildDoubleDigits(seconds),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDoubleDigits(String digits) {
    return List.generate(digits.length, (index) {
      return _buildTimeCircle(digits[index]);
    });
  }

  Widget _buildTimeCircle(String time) {
    return Container(
      width: 18.w,
      height: 18,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(time,
          style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey900)),
    );
  }
}
