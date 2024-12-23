import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/snackbar_util.dart';

enum ReportType { comment, post }

class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({
    super.key,
    required this.title,
    required this.type,
    required this.target,
    required this.postId,
  });

  final ReportType type;
  final String title;
  final Object target;
  final String postId;

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  int? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  final FocusNode _otherReasonFocus = FocusNode();
  String? _errorText;
  bool _isSubmitting = false;
  final int _maxLength = 100;
  bool _blockUser = false; // 사용자 차단 여부 상태 추가

  late List<String> _reasons;

  @override
  void initState() {
    super.initState();

    _reasons = [
      Intl.message('post_report_reason_1'),
      Intl.message('post_report_reason_2'),
      Intl.message('post_report_reason_3'),
      Intl.message('post_report_reason_4'),
      Intl.message('post_report_reason_5'),
    ];

    _otherReasonController.addListener(_validateOtherReason);
    _otherReasonFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _otherReasonController.removeListener(_validateOtherReason);
    _otherReasonController.dispose();
    _otherReasonFocus.removeListener(_onFocusChange);
    _otherReasonFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_otherReasonFocus.hasFocus) {
      _validateOtherReason();
    }
  }

  void _validateOtherReason() {
    if (_selectedReason == 4) {
      final text = _otherReasonController.text.trim();
      setState(() {
        if (text.isEmpty) {
          _errorText = S.of(context).post_report_other_input;
        } else if (text.length > _maxLength) {
          _errorText = '최대 $_maxLength자까지 입력 가능합니다.';
        } else {
          _errorText = null;
        }
      });
    }
  }

  Widget _buildReasonOptions() {
    return Column(
      children: _reasons.asMap().entries.map((entry) {
        return CustomRadioListTile(
          title: entry.value,
          value: entry.key,
          groupValue: _selectedReason,
          onChanged: _isSubmitting
              ? null
              : (int? newValue) {
                  setState(() {
                    _selectedReason = newValue;
                    if (newValue != 4) {
                      _otherReasonController.clear();
                      _errorText = null;
                    }
                  });
                },
        );
      }).toList(),
    );
  }

  Widget _buildOtherReasonField() {
    if (_selectedReason != 4) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: _otherReasonController,
        focusNode: _otherReasonFocus,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          hintText: S.of(context).post_report_other_input,
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
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7),
          counterText: '${_otherReasonController.text.length}/$_maxLength',
          counterStyle: getTextStyle(AppTypo.caption10SB, AppColors.grey500),
        ),
        maxLength: _maxLength,
        maxLines: 3,
        minLines: 3,
        textInputAction: TextInputAction.newline,
        style: getTextStyle(AppTypo.body16R, AppColors.grey900),
      ),
    );
  }

  Widget _buildBlockUserCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _blockUser,
              onChanged: _isSubmitting
                  ? null
                  : (bool? value) {
                      setState(() {
                        _blockUser = value ?? false;
                      });
                    },
              activeColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).block_user_label, // "해당 사용자 차단하기" 등의 번역 텍스트
              style: getTextStyle(
                AppTypo.caption12R,
                _blockUser ? AppColors.grey900 : AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      SnackbarUtil().showSnackbar(S.of(context).post_report_reason_input);
      return;
    }

    if (_selectedReason == 4 && _otherReasonController.text.trim().isEmpty) {
      setState(() {
        _errorText = S.of(context).post_report_other_input;
      });
      _otherReasonFocus.requestFocus();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reason = _reasons[_selectedReason!];
      final additionalText = _otherReasonController.text.trim();

      if (widget.type == ReportType.comment) {
        final commentsNotifier = ref.read(
          commentsNotifierProvider(widget.postId, 1, 10).notifier,
        );
        await commentsNotifier.reportComment(
          widget.target as CommentModel,
          reason,
          additionalText,
          blockUser: _blockUser, // 차단 여부 전달
        );
      } else {
        await reportPost(
          ref,
          widget.target as PostModel,
          reason,
          additionalText,
          blockUser: _blockUser, // 차단 여부 전달
        );
      }

      if (!mounted) return;

      SnackbarUtil().showSnackbar(
        S.of(context).post_report_success,
      );

      Navigator.of(context).pop(true);
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      SnackbarUtil().showSnackbar(S.of(context).post_report_fail,
          backgroundColor: Colors.red);
      rethrow;
    }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                S.of(context).post_report_reason_label,
                style: getTextStyle(AppTypo.caption10SB, AppColors.grey900),
              ),
            ),
            const SizedBox(height: 12),
            _buildReasonOptions(),
            _buildOtherReasonField(),
            _buildBlockUserCheckbox(), // 체크박스 추가
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                disabledBackgroundColor: AppColors.grey300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      S.of(context).post_report_label,
                      style: getTextStyle(AppTypo.body14M, Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRadioListTile extends StatelessWidget {
  final String title;
  final int value;
  final int? groupValue;
  final ValueChanged<int?>? onChanged;

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
    final isEnabled = onChanged != null;

    return InkWell(
      onTap: isEnabled ? () => onChanged?.call(value) : null,
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
                    if (states.contains(WidgetState.disabled)) {
                      return AppColors.grey300;
                    }
                    return AppColors.grey300;
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
