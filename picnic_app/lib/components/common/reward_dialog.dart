import 'package:flutter/material.dart';
import 'package:picnic_app/components/vote/home/reward_dialog.dart';
import 'package:picnic_app/models/reward.dart';

showRewardDialog(BuildContext context, RewardModel data) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Builder(
        builder: (BuildContext context) {
          return RewardDialog(
            data: data,
          );
        },
      );
    },
  );
}
