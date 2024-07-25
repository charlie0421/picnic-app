import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_platform/universal_platform.dart';

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

String formatNumberWithComma<T>(T number) {
  final numberFormat = NumberFormat("#,###");
  return T == String
      ? numberFormat.format(int.parse(number as String))
      : numberFormat.format(number);
}

String formatTimeAgo(BuildContext context, DateTime timestamp) {
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
    return S.of(context).label_time_ago_right_now;
  }
}

bool isIPad(BuildContext context) {
  if (!UniversalPlatform.isIOS) return false;
  final Size screenSize = getPlatformScreenSize(context);
  // Typical iPad screen size ranges
  const double iPadSizeThreshold = 768.0; // Width in portrait mode
  return screenSize.width >= iPadSizeThreshold ||
      screenSize.height >= iPadSizeThreshold;
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

bool isIOS() {
  if (UniversalPlatform.isWeb) {
    return false;
  }
  return Platform.isIOS;
}

bool isAndroid() {
  return Platform.isAndroid;
}

bool isMobile() {
  if (UniversalPlatform.isWeb) {
    return false;
  } else {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
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
        width: getPlatformScreenSize(context).width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.Grey100,
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

Widget buildPlaceholderImage() {
  return Shimmer.fromColors(
    baseColor: AppColors.Grey200,
    highlightColor: AppColors.Grey100,
    child: Container(
      color: AppColors.Grey00,
    ),
  );
}

Widget buildLoadingOverlay() {
  return Shimmer.fromColors(
    baseColor: AppColors.Grey300,
    highlightColor: AppColors.Grey100,
    child: Container(
      color: AppColors.Grey00,
    ),
  );

  Container(
    alignment: Alignment.center,
    child: const CircularProgressIndicator(
      color: Colors.green,
    ), // 로딩바
  );
}
//
// Future<String?> getRecentImagePath() async {
//   final externalStorageDirectory = await getExternalStorageDirectory();
//   final directory = Directory('${externalStorageDirectory?.path}/DCIM/Camera');
//   final files = directory.listSync();
//   final sortedFiles = files
//       .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
//   final recentFile = sortedFiles.first;
//
//   if (recentFile is File) {
//     return recentFile.path;
//   } else {
//     return null;
//   }
// }

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  showSimpleDialog(
      context: context,
      content: S.of(context).text_copied_address,
      onOk: () => Navigator.of(context).pop());
}

Size getPlatformScreenSize(BuildContext context) {
  if (UniversalPlatform.isWeb) {
    return const Size(393 * 2, 852 * 2);
  }
  return MediaQuery.of(context).size;
}

Future<bool> checkSuperAdmin() async {
  final response =
      await supabase.from('auth.users').select('is_super_admin').single();

  logger.i('response[\'is_super_admin\'] : ${response['is_super_admin']}');
  if (response['is_super_admin'] == true) {
    return true;
  }

  return true;
}

String getLocaleTextFromJson(Map<String, dynamic> json) {
  String locale = Intl.getCurrentLocale().split('_').first;

  if (json.isEmpty) {
    return '';
  }

  if (json.containsKey(locale)) {
    return json[locale];
  }
  return json['en'];
}
