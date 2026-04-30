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

  // ProviderContainer 는 ProviderScope subtree 의 root 에서 살아있으며 특정
  // widget unmount 의 영향을 받지 않는다. dialog 의 onOk 가 호출될 때 호출자
  // widget 이 이미 deactivate 되었어도 container.read 는 안전하게 작동.
  // (Sentry PICNIC-APP-4XZ: "Bad state: Using "ref" when a widget is about to
  //  or has been unmounted is unsafe" — Consumer 의 ref 를 async callback 에서
  //  쓰면서 발생한 fatal StateError. logoutUser 가 true 인 정상 경로에서 빈번.)
  final container = ProviderScope.containerOf(context);

  showSimpleDialog(
    content: AppLocalizations.of(context).error_message_withdrawal,
    onOk: () {
      if (logoutUser) {
        container.read(userInfoProvider.notifier).logout();
      }

      final navContext = navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(navContext).pop();
      }
    },
  );

  return true;
}
