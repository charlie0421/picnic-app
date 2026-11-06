import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// 탈퇴한 사용자의 앱 내 주요 액션을 차단하고 안내합니다.
///
/// 반환값이 `true`이면 이미 탈퇴 사용자이므로 호출 측 로직을 즉시 중단해야 합니다.
/// 프로필 조회 중에 호출 화면이 사라졌거나 로그인 계정이 바뀌어도 `true`를
/// 반환합니다. 그 경우 다이얼로그와 logout 은 없습니다.
Future<bool> showWithdrawalBlockedDialog({
  required BuildContext context,
  required WidgetRef ref,
  bool logoutUser = true,
}) async {
  if (!context.mounted) return true;

  // await 전에, 호출 화면이 살아 있을 때 잡아 둔다. await 뒤에는 `ref` 를 쓰지
  // 않는다 - 호출 위젯이 이미 폐기됐을 수 있다 (Sentry PICNIC-APP-5KE).
  //
  // ProviderContainer 는 ProviderScope subtree 의 root 에서 살아있으며 특정
  // widget unmount 의 영향을 받지 않는다. dialog 의 onOk 가 호출될 때 호출자
  // widget 이 이미 deactivate 되었어도 container.read 는 안전하게 작동.
  // (Sentry PICNIC-APP-4XZ: "Bad state: Using "ref" when a widget is about to
  //  or has been unmounted is unsafe" — Consumer 의 ref 를 async callback 에서
  //  쓰면서 발생한 fatal StateError. logoutUser 가 true 인 정상 경로에서 빈번.)
  final container = ProviderScope.containerOf(context, listen: false);
  // 이 확인을 요청한 계정. 프로필 캐시가 아니라 실제 인증 상태로 판단한다 -
  // 늦게 도착한 다른 계정의 프로필 응답이 캐시를 덮어쓸 수 있다. 계정 전환
  // 횟수도 함께 잡아 A → B → A 처럼 같은 ID 로 돌아온 경우도 다른 소유자로 본다.
  final owner = _AuthOwner.capture(container);

  UserProfilesModel? userProfile;
  try {
    userProfile = await ref.read(userInfoProvider.notifier).getUserProfiles();
  } catch (_) {
    // 프로필을 새로고침하지 못하면 기존 캐시 값을 사용합니다.
  }

  // 조회 중에 화면이 떠났거나 계정이 바뀌었으면 이 결과는 호출자의 것이 아니다.
  // 다이얼로그·logout 없이 호출자를 멈춘다.
  if (!context.mounted || !owner.isCurrent) return true;
  if (owner.sessionChanged) {
    // 세션이 바뀌었는데 ID 는 같다: 토큰 갱신일 수도, 아직 전달되지 않은
    // A → B → A 일 수도 있다. 큐에 든 인증 이벤트가 전달된 뒤 다시 확인한다.
    await owner.letQueuedAuthEventsArrive();
    if (!context.mounted || !owner.isCurrent) return true;
  }

  userProfile ??= _ownedCache(
    container.read(userInfoProvider).value,
    owner.userId,
  );

  final isWithdrawn = userProfile?.deletedAt != null;

  if (!isWithdrawn) {
    return false;
  }

  showSimpleDialog(
    content: AppLocalizations.of(context).error_message_withdrawal,
    onOk: () {
      // 다이얼로그가 열린 사이에 계정이 바뀌었으면(A → B → A 포함) 지금 계정을
      // 로그아웃하지 않는다. 세션만 바뀌었으면 큐에 든 인증 이벤트를 기다린 뒤
      // 결정한다. 다이얼로그는 기다리지 않고 지금 닫는다.
      if (logoutUser && owner.isCurrent) {
        if (!owner.sessionChanged) {
          container.read(userInfoProvider.notifier).logout();
        } else {
          unawaited(
            owner.letQueuedAuthEventsArrive().then((_) {
              // 컨테이너가 폐기됐으면 tracker 도 폐기되어 isCurrent 가 false 다.
              if (owner.isCurrent) {
                container.read(userInfoProvider.notifier).logout();
              }
            }),
          );
        }
      }

      final navContext = navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        Navigator.of(navContext).pop();
      }
    },
  );

  return true;
}

/// 현재 Supabase 클라이언트. 초기화되지 않았으면 null.
SupabaseClient? _authClient() {
  try {
    return supabase;
  } on StateError {
    return null;
  }
}

/// 이 ProviderScope 가 관측한 계정 전환 횟수.
///
/// 컨테이너당 하나이고 컨테이너와 함께 구독을 해제한다. 다이얼로그마다
/// 리스너를 붙이지 않으므로 barrier 로 닫힌 다이얼로그가 리스너를 남기지 않는다.
/// 사용자 ID 가 바뀔 때만 센다 - 같은 계정의 토큰 갱신과 리플레이는 전환이
/// 아니다.
final class _AuthTransitions {
  _AuthTransitions(this.client);

  final SupabaseClient? client;
  int count = 0;

  /// 컨테이너와 함께 폐기되면 true. 이 tracker 로 잡은 소유자는 무효가 된다.
  bool disposed = false;
}

final _authTransitionsProvider = Provider<_AuthTransitions>((ref) {
  final client = _authClient();
  final tracker = _AuthTransitions(client);
  if (client == null) return tracker;
  var current = client.auth.currentUser?.id;
  final events = client.auth.onAuthStateChange.listen(
    (state) {
      final next = state.session?.user.id;
      if (next == current) return;
      current = next;
      tracker.count++;
    },
    // 인증 오류에는 세션 정보가 담길 수 있다. 기록하지 않고 마지막 상태를 유지한다.
    onError: (Object _, StackTrace _) {},
  );
  ref.onDispose(() {
    tracker.disposed = true;
    events.cancel();
  });
  return tracker;
}, name: 'withdrawnUserGuardAuthTransitions');

/// 한 번의 확인을 요청한 계정, 그때의 세션 인스턴스, 그때까지의 계정 전환 횟수.
final class _AuthOwner {
  _AuthOwner._(this._tracker, this.userId, this._session, this._count);

  factory _AuthOwner.capture(ProviderContainer container) {
    var tracker = container.read(_authTransitionsProvider);
    if (!identical(tracker.client, _authClient())) {
      // 클라이언트가 바뀌었으면 이전 구독을 해제하고 지금 클라이언트를 관측한다.
      container.invalidate(_authTransitionsProvider);
      tracker = container.read(_authTransitionsProvider);
    }
    return _AuthOwner._(
      tracker,
      tracker.client?.auth.currentUser?.id,
      tracker.client?.auth.currentSession,
      tracker.count,
    );
  }

  final _AuthTransitions _tracker;
  final String? userId;

  /// 비교에만 쓴다. 세션 내용은 읽거나 기록하지 않는다.
  final Object? _session;
  final int _count;

  /// 같은 클라이언트에서, 관측된 전환 없이, 같은 사용자가 로그인해 있는지.
  /// tracker 가 폐기됐으면(컨테이너 폐기 포함) 언제나 false.
  bool get isCurrent {
    final client = _authClient();
    return !_tracker.disposed &&
        identical(client, _tracker.client) &&
        _tracker.count == _count &&
        client?.auth.currentUser?.id == userId;
  }

  /// 확인 이후 세션 인스턴스가 바뀌었는지. 같은 계정의 토큰 갱신도, 이벤트가
  /// 아직 전달되지 않은 계정 전환도 여기서는 같아 보인다.
  bool get sessionChanged =>
      !identical(_tracker.client?.auth.currentSession, _session);

  /// 한 프레임을 기다린다. gotrue 는 세션을 바꾸는 턴에 이벤트를 microtask 로
  /// 예약하므로, 그 사이 예약된 인증 이벤트는 프레임 전에 [_tracker] 에 전달된다.
  /// 기다린 뒤에는 호출 측이 [isCurrent] 와 수명을 다시 확인해야 한다.
  Future<void> letQueuedAuthEventsArrive() =>
      SchedulerBinding.instance.endOfFrame;
}

/// [cached] 가 다른 계정의 프로필이면 캐시가 없는 것으로 본다.
UserProfilesModel? _ownedCache(UserProfilesModel? cached, String? owner) {
  if (cached == null || owner == null) return cached;
  return cached.id == owner ? cached : null;
}
