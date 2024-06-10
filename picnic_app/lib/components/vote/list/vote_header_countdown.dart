import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/ui/style.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime stopAt;

  CountdownTimer({required this.stopAt});

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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.stopAt.difference(DateTime.now());
        if (_timeLeft.isNegative) {
          _timeLeft = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 종료시간까지 24시간 초과로 남음
    // 종료시간까지 1시간 초과 ~ 24시간
    // 종료시간까지 0초 초과 ~ 1시간
    // 종료시간까지 0(종료됨)

    final days = _timeLeft.inDays.remainder(24).toString().padLeft(2, '0');
    final hours = _timeLeft.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes =
        _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    setState(() {
      if (_timeLeft.inHours > 24) {
        _color = AppColors.Mint500;
      } else if (_timeLeft.inHours > 1) {
        _color = AppColors.Sub500;
      } else if (_timeLeft.inMinutes > 0) {
        _color = AppColors.Point500;
      } else {
        _color = AppColors.Gray300;
      }
    });

    return SizedBox(
      height: 18.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ..._buildDoubleDigits(days),
          Text(' D ',
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Gray900)),
          ..._buildDoubleDigits(hours),
          Text(' : ',
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Gray900)),
          ..._buildDoubleDigits(minutes),
          Text(' : ',
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Gray900)),
          ..._buildDoubleDigits(seconds),
        ],
      ),
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
      height: 18.w,
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
      ),
      margin: EdgeInsets.symmetric(horizontal: 4),
      // 추가: 숫자 간 간격 조정
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4), // Circular shape
      ),
      child: Text(time,
          style: getTextStyle(AppTypo.CAPTION12M, AppColors.Gray900)),
    );
  }
}
