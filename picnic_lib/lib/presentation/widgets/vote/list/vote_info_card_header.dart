import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_card_layout.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteCardInfoHeader extends StatelessWidget {
  const VoteCardInfoHeader({
    super.key,
    required this.title,
    required this.stopAt,
    this.onRefresh,
    required this.status,
  });

  final String title;
  final DateTime stopAt;
  final VoidCallback? onRefresh;
  final VoteStatus status;

  /// Minimum header extent for the card's short-viewport scroll fallback.
  double heightForWidth(BuildContext context, double width) {
    final titleHeight = VoteCardLayout.textHeight(
      context,
      title,
      PicnicUi.text(size: 16, weight: FontWeight.w600),
      maxWidth: (width - (status == VoteStatus.active ? 96 : 0)).clamp(
        1,
        double.infinity,
      ),
      maxLines: 2,
    );
    final timerHeight = status == VoteStatus.end
        ? VoteCardLayout.textHeight(
            context,
            'Ag',
            getTextStyle(AppTypo.body14B, AppColors.primary500),
            maxWidth: width,
          )
        : CountdownTimer.digitSize + (status == VoteStatus.upcoming ? 36 : 0);
    return titleHeight.clamp(
          status == VoteStatus.active ? 48 : 0,
          double.infinity,
        ) +
        16 +
        timerHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(
            minHeight: status == VoteStatus.active ? 48 : 0,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: status == VoteStatus.active ? 48 : 0,
                ),
                child: Text(
                  title,
                  style: PicnicUi.text(size: 16, weight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status == VoteStatus.active)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).refreshIndicatorSemanticLabel,
                      onPressed: onRefresh,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      padding: const EdgeInsets.all(12),
                      icon: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/reset_style=line.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        CountdownTimer(endTime: stopAt, status: status, onRefresh: onRefresh),
      ],
    );
  }
}
