import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteNoItem extends StatelessWidget {
  const VoteNoItem({
    super.key,
    required this.status,
    required this.context,
  });

  final VoteStatus status;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    String message;
    switch (status) {
      case VoteStatus.active:
        message = AppLocalizations.of(context).message_noitem_vote_active;
        break;
      case VoteStatus.end:
        message = AppLocalizations.of(context).message_noitem_vote_end;
        break;
      case VoteStatus.upcoming:
        message = AppLocalizations.of(context).message_noitem_vote_upcoming;
        break;
      default:
        return Container();
    }
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(message,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey500)),
    );
  }
}
