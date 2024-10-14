import 'package:flutter/foundation.dart';
import 'package:picnic_app/enums.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_protector_provider.g.dart';

@riverpod
class IsScreenProtector extends _$IsScreenProtector {
  @override
  bool build() {
    if (kDebugMode) {
      return false;
    }

    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin));
    final portalType =
        ref.watch(navigationInfoProvider.select((value) => value.portalType));

    state = portalType == PortalType.pic;

    if (isAdmin == true) {
      state = false;
    }

    logger.e('isAdmin: $isAdmin, portalType: $portalType, state: $state');
    return state;
  }
}
