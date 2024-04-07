import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/ui/style.dart';

String formatCount(int number, String labelName) {
  final String viewString = Intl.getCurrentLocale() == 'ko'
      ? '${formatViewCountNumberKo(number)} ${Intl.message(labelName)}'
      : '${formatViewCountNumberEn(number)} ${Intl.message(labelName)}';
  return viewString;
}

String formatViewCountNumberKo(int number) {
  if (number >= 100000000) {
    return '${(number / 100000000).toStringAsFixed(1)}억';
  } else if (number >= 10000) {
    return '${(number / 10000).toStringAsFixed(1)}만';
  } else {
    return NumberFormat(number < 1000 ? '###' : '#,###').format(number);
  }
}

String formatViewCountNumberEn(int number) {
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  } else if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else {
    return NumberFormat(number < 1000 ? '###' : '#,###').format(number);
  }
}

String formatTimeAgo(DateTime timestamp) {
  final now = DateTime.now().toUtc();
  final difference = now.difference(timestamp);

  if (difference.inDays >= 1) {
    return Intl.message('label_time_ago_day',
        args: [difference.inDays.toString()]);
  } else if (difference.inHours >= 1) {
    return Intl.message('label_time_ago_hour',
        args: [difference.inHours.toString()]);
  } else if (difference.inMinutes >= 1) {
    return Intl.message('label_time_ago_minute',
        args: [difference.inMinutes.toString()]);
  } else {
    return Intl.message('label_time_ago_right_now');
  }
}

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide > 600;
}

double itemPerWidth(BuildContext context) {
  return kIsWeb
      ? Constants.webMaxWidth / 4.5 - 10
      : isTablet(context)
          ? MediaQuery.of(context).size.width / 7.5 - 10
          : MediaQuery.of(context).size.width / 4.5 - 10;
}

String formatCurrentTime() {
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd HH:mm:ss', Intl.getCurrentLocale());
  return formatter.format(now);
}

Color getComplementaryColor(Color color) {
  // RGB 채널에서 각 값을 255에서 빼서 보색을 찾습니다.
  int red = 255 - color.red;
  int green = 255 - color.green;
  int blue = 255 - color.blue;

  // 계산된 RGB 값을 사용하여 새로운 Color 객체를 생성합니다.
  return Color.fromARGB(255, red, green, blue);
}

bool isWeb() {
  return kIsWeb;
}

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

bool isDesktop() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

bool isMacOS() {
  return Platform.isMacOS;
}

bool isWindows() {
  return Platform.isWindows;
}

bool isLinux() {
  return Platform.isLinux;
}

void showOverlayToast(BuildContext context, Widget child) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.Gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 1), () {
    overlayEntry.remove();
  });
}

Widget buildLoadingOverlay() {
  return Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(
      color: Colors.green,
    ), // 로딩바
  );
}
