import 'package:flutter/material.dart';

class BottomSheetHeader extends StatelessWidget {
  BottomSheetHeader({super.key, required this.title});
  String title = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 50),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 50,
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.close,
                  size: 30,
                )),
          ),
        ],
      ),
    );
  }
}
