import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteCommonTitle extends StatelessWidget {
  final String title;

  /// 제목 줄 수 상한. 기본(null)은 제한 없이 줄바꿈한다. 좁은 화면 + 큰 글자
  /// 배율에서 제목이 헤더 전체를 차지하면 안 되는 호출자(소멸 예정 캔디 안내
  /// 다이얼로그)가 제한한다. 넘치는 부분은 말줄임.
  final int? maxLines;

  const VoteCommonTitle({super.key, required this.title, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(16),
        vertical: PicnicUi.vertical(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary500,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary500, width: 1.5),
      ),
      child: Row(
        children: [
          _buildArrow(),
          SizedBox(width: PicnicUi.horizontal(8)),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: PicnicUi.text(size: 16, weight: FontWeight.w500)
                      .copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1
                          ..color = AppColors.primary500
                          ..strokeJoin = StrokeJoin.miter
                          ..strokeMiterLimit = 28.96,
                      ),
                  softWrap: true,
                  maxLines: maxLines,
                  overflow: maxLines == null
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: PicnicUi.text(
                    size: 16,
                    weight: FontWeight.w500,
                    color: PicnicUi.secondaryForeground,
                  ),
                  softWrap: true,
                  maxLines: maxLines,
                  overflow: maxLines == null
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: PicnicUi.horizontal(8)),
          Transform.rotate(angle: 3.14, child: _buildArrow()),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return SvgPicture.asset(
      package: 'picnic_lib',
      'assets/icons/play_style=fill.svg',
      width: PicnicUi.horizontal(16),
      height: 16,
      colorFilter: ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
    );
  }
}

/// Adaptive presentation for the vote period shown below a vote title.
class VotePeriodLabel extends StatelessWidget {
  const VotePeriodLabel({super.key, required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(12),
        vertical: PicnicUi.vertical(8),
      ),
      decoration: PicnicUi.surfaceDecoration(radius: 12),
      child: Text(
        period,
        style: PicnicUi.text(size: 12, color: PicnicUi.secondaryText),
        softWrap: true,
        textAlign: TextAlign.center,
      ),
    );
  }
}
