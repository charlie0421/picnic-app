import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogCommonCancelButton extends StatelessWidget {
  final VoidCallback callback;

  const DialogCommonCancelButton({required this.callback, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 43,
      child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(const Color(0xff8A8A8A)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.grey)))),
          onPressed: callback,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              Intl.message('button_cancel'),
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.normal),
            ),
          )),
    );
  }
}
