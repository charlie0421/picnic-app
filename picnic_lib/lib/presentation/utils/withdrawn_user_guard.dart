import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

/// 탈퇴한 사용자의 앱 내 주요 액션을 차단하고 안내합니다.
///
/// 반환값이 `true`이면 이미 탈퇴 사용자이므로 호출 측 로직을 즉시 중단해야 합니다.
Future<bool> showWithdrawalBlockedDialog({
  required BuildContext context,
  required WidgetRef ref,
  bool logoutUser = true,
}) async {
  UserProfilesModel? userProfile;
  try {
    userProfile = await ref.read(userInfoProvider.notifier).getUserProfiles();
  } catch (_) {
    // 프로필을 새로고침하지 못하면 기존 캐시 값을 사용합니다.
  }

  userProfile ??= ref.read(userInfoProvider).value;

  final isWithdrawn = userProfile?.deletedAt != null;

  if (!isWithdrawn) {
    return false;
  }

  if (!context.mounted) return true;

  showSimpleDialog(
    content: AppLocalizations.of(context).error_message_withdrawal,
    onOk: () {
      if (logoutUser) {
        ref.read(userInfoProvider.notifier).logout();
      }

      final navContext = navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(navContext).pop();
      }
    },
  );

  return true;
}
