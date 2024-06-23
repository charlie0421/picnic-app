import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';

class DialogCommonCancelButton extends StatelessWidget {
  final VoidCallback callback;

  const DialogCommonCancelButton({required this.callback, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 43,
      child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all<Color>(const Color(0xff8A8A8A)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.grey)))),
          onPressed: callback,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              S.of(context).button_cancel,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.normal),
            ),
          )),
    );
  }
}
