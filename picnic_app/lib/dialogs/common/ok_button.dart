import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';

class DialogCommonOkButton extends StatelessWidget {
  final VoidCallback callback;

  const DialogCommonOkButton({required this.callback, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 43,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.all(0),
          ),
          onPressed: callback,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A481E), Color(0xFF14983F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30.0), // 버튼 모서리 둥글게 설정
            ),
            child: Container(
              alignment: Alignment.center,
              // 내부 텍스트 중앙 정렬
              child: Text(
                S.of(context).button_ok,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.normal),
              ),
            ),
          )),
    );
  }
}
