import 'package:flutter/material.dart';
import 'package:picnic_app/components/vote/home/reward_dialog.dart';
import 'package:picnic_app/models/reward.dart';

showRewardDialog(BuildContext context, RewardModel data) {
  return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return Transform.scale(
          scale: animation1.value,
          child: Opacity(
            opacity: animation1.value,
            child: RewardDialog(
              data: data,
            ),
          ),
        );
      });
}
