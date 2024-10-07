import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/ui/style.dart';

class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({super.key, required this.title, required this.comment});
  final String title;
  final CommentModel comment;

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  int? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  String? _errorText;
  final int _maxLength = 100;

  final List<String> _reasons = [
    '미풍양속에 어긋나는 게시물',
    '남녀, 인종차별적 게시물',
    '불쾌한 욕설이 포함된 게시물',
    '광고/홍보성 게시물',
    '기타'
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(38),
        side: const BorderSide(color: AppColors.sub500, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: getTextStyle(AppTypo.caption12B, AppColors.primary500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '신고사유',
                style: getTextStyle(AppTypo.caption10SB, AppColors.grey900),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildReasonOptions(),
            if (_selectedReason == 4) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  hintText: '사유를 작성해주세요.',
                  hintStyle: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.grey400,
                  ),
                  errorText: _errorText,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: AppColors.primary500,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: AppColors.grey300,
                      width: 1,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7),
                  counterText: '', // Hide default counter
                ),
                maxLength: _maxLength,
                maxLines: 3,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                style: getTextStyle(AppTypo.body16R, AppColors.grey900),
                onFieldSubmitted: (value) => (),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReport,
              child: const Text(
                '신고하기',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReasonOptions() {
    return _reasons.asMap().entries.map((entry) {
      return CustomRadioListTile(
        title: entry.value,
        value: entry.key,
        groupValue: _selectedReason,
        onChanged: (int? newValue) {
          setState(() {
            _selectedReason = newValue;
            if (newValue != 4) {
              _otherReasonController.clear();
              _errorText = null;
            }
          });
        },
      );
    }).toList();
  }

  void _submitReport() {
    if (_selectedReason == 4 && _otherReasonController.text.trim().isEmpty) {
      setState(() {
        _errorText = '기타 사유를 입력해주세요.';
      });
      return;
    }

    reportComment(ref, widget.comment, _reasons[_selectedReason!],
        _otherReasonController.text);

    // Handle report submission
    Navigator.of(context).pop();
  }
}

class CustomRadioListTile extends StatelessWidget {
  final String title;
  final int value;
  final int? groupValue;
  final ValueChanged<int?> onChanged;

  const CustomRadioListTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<int>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: AppColors.primary500,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary500;
                    }
                    return AppColors.grey300; // 선택되지 않은 경우의 회색
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: getTextStyle(
                  AppTypo.caption12R,
                  isSelected ? AppColors.grey900 : AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
