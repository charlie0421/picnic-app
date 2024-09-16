import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

import '../../../generated/l10n.dart';

class PostWriteHeader extends StatelessWidget {
  final VoidCallback onSave;

  const PostWriteHeader({
    super.key,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: '1',
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style: getTextStyle(AppTypo.body14B, AppColors.primary500),
            underline: Container(
              height: 2,
              color: AppColors.primary500,
            ),
            onChanged: (String? newValue) {},
            items: <String>['1', '2', '3', '4']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(S.of(context).post_header_temporary_save,
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
              SizedBox(width: 16.cw),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      backgroundColor: AppColors.grey00,
                      textStyle: getTextStyle(AppTypo.body14B),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                            color: AppColors.primary500, width: 1),
                      ),
                    ),
                    onPressed: onSave,
                    child: Text(S.of(context).post_header_publish,
                        style: getTextStyle(
                            AppTypo.body14B, AppColors.primary500))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
