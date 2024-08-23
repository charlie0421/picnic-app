import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/ui/style.dart';

class PostWriteHeader extends StatelessWidget {
  final VoidCallback onSave;

  const PostWriteHeader({
    Key? key,
    required this.onSave,
    required this.isAnonymous,
    required this.onAnonymousChanged,
  }) : super(key: key);
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('임시저장',
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
              SizedBox(width: 8.w),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  backgroundColor: AppColors.grey00,
                  textStyle: getTextStyle(AppTypo.body14B),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side:
                        const BorderSide(color: AppColors.primary500, width: 1),
                  ),
                ),
                onPressed: onSave,
                child: const Text('게시'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
