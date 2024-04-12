import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

Future<void> showCustomTrackingDialog(BuildContext context) async =>
    showCupertinoModalPopup(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Intl.getCurrentLocale() == 'ko'
              ? Image.asset('assets/images/ATT_KO.png')
              : Image.asset('assets/images/ATT_EN.png'),
        ),
      ),
    );
