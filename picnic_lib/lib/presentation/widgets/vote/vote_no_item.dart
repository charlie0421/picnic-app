import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteNoItem extends StatelessWidget {
  const VoteNoItem({super.key, required this.status, required this.context});

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
    // A 100 minimum: at 2.0x+ on narrow screens the id/vi message wraps to
    // three lines and was cut by a fixed 100. heightFactor 1 keeps the old
    // height (a bare alignment would stretch to fill the parent).
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: Center(
        heightFactor: 1,
        child: Text(
          message,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey500),
        ),
      ),
    );
  }
}
