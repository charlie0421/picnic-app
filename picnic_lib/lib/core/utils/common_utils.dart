import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

/// 공통 유틸리티 클래스
class CommonUtils {
  final WidgetRef ref;
  final BuildContext context;

  CommonUtils(this.ref, this.context);

  /// 프로필 새로고침
  void refreshUserProfile() {
    if (!context.mounted) return;
    ref.read(userInfoProvider.notifier).getUserProfiles();
  }

  /// 에러 다이얼로그 표시
  void showErrorDialog(String message, {dynamic error}) {
    if (!context.mounted) return;
    showSimpleErrorDialog(context, message, error: error);
  }
}
