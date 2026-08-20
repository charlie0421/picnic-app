import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart';

void main() {
  test(
    'preflight creates, persists, subscribes, then loads signed media extra',
    () async {
      final calls = <String>[];
      final signals = StreamController<void>.broadcast();
      final reference = AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      );
      final claim = PangleClaimModel(
        reference: reference,
        platform: 'android',
        signedToken: 'signed-token',
        expiresAt: DateTime.utc(2030),
      );
      final result =
          await PangleClaimPreflight(
            createClaim:
                ({
                  required platform,
                  required placementId,
                  required clientRequestId,
                }) async {
                  calls.add('create:$platform:$placementId:$clientRequestId');
                  return claim;
                },
            persist: (owner, value) async =>
                calls.add('persist:$owner:${value.id}'),
            pollingSignals: signals.stream,
            poll: (owner, value) async => calls.add('poll:$owner:${value.id}'),
            load: (placement, mediaExtra) async {
              calls.add('load:$placement:$mediaExtra');
              return true;
            },
          ).execute(
            ownerUserId: 'user-a',
            platform: 'android',
            placementId: 'rewarded-placement',
            clientRequestId: 'request-a',
          );
      expect(calls, [
        'create:android:rewarded-placement:request-a',
        'persist:user-a:claim-a',
        'load:rewarded-placement:user-a,android,v2.signed-token',
      ]);
      signals.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(calls.last, 'poll:user-a:claim-a');
      await result.subscription.cancel();
      await signals.close();
    },
  );

  test('preflight cancels polling subscription when load throws', () async {
    final signals = StreamController<void>.broadcast();
    var polls = 0;
    final claim = PangleClaimModel(
      reference: const AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      ),
      platform: 'android',
      signedToken: 'token',
      expiresAt: DateTime.utc(2030),
    );
    final preflight = PangleClaimPreflight(
      createClaim:
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) async => claim,
      persist: (_, _) async {},
      pollingSignals: signals.stream,
      poll: (_, _) async => polls++,
      load: (_, _) => Future<bool>.error(StateError('native load failed')),
    );
    await expectLater(
      preflight.execute(
        ownerUserId: 'user-a',
        platform: 'android',
        placementId: 'placement',
        clientRequestId: 'request',
      ),
      throwsStateError,
    );
    signals.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(polls, 0);
    await signals.close();
  });

  test('preflight returns false when native load times out', () async {
    final signals = StreamController<void>.broadcast();
    final claim = PangleClaimModel(
      reference: const AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      ),
      platform: 'android',
      signedToken: 'token',
      expiresAt: DateTime.utc(2030),
    );
    final result =
        await PangleClaimPreflight(
          createClaim:
              ({
                required platform,
                required placementId,
                required clientRequestId,
              }) async => claim,
          persist: (_, _) async {},
          pollingSignals: signals.stream,
          poll: (_, _) async {},
          load: (_, _) => Completer<bool>().future,
          loadTimeout: const Duration(milliseconds: 1),
        ).execute(
          ownerUserId: 'user-a',
          platform: 'android',
          placementId: 'placement',
          clientRequestId: 'request',
        );
    expect(result.loaded, isFalse);
    await result.subscription.cancel();
    await signals.close();
  });

  test(
    'polling failure after a signal never escapes as an unhandled async error',
    () async {
      final uncaught = <Object>[];
      final reported = <Object>[];
      final signals = StreamController<void>.broadcast();
      final claim = PangleClaimModel(
        reference: const AdRewardReference(
          type: AdRewardReferenceType.pangleClaim,
          id: 'claim-a',
        ),
        platform: 'android',
        signedToken: 'token',
        expiresAt: DateTime.utc(2030),
      );
      PangleClaimPreflightResult? result;
      await runZonedGuarded(() async {
        result =
            await PangleClaimPreflight(
              createClaim:
                  ({
                    required platform,
                    required placementId,
                    required clientRequestId,
                  }) async => claim,
              persist: (_, _) async {},
              pollingSignals: signals.stream,
              poll: (_, _) async =>
                  throw const FormatException('Ad reward status decode failed'),
              load: (_, _) async => true,
              onPollError: (error, _) => reported.add(error),
            ).execute(
              ownerUserId: 'user-a',
              platform: 'android',
              placementId: 'placement',
              clientRequestId: 'request',
            );
        signals.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }, (error, stackTrace) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(reported.single, isFormatException);
      await result?.subscription.cancel();
      await signals.close();
    },
  );

  test(
    'poll closure that throws synchronously routes to onPollError instead of escaping the zone',
    () async {
      // 프로덕션 결함 (PICNIC-APP-5G9): dispose 된 ConsumerState 의 ref.read 는
      // Future 를 만들기 전에 동기로 던진다. async 클로저와 달리 catchError 가
      // 붙기 전에 예외가 전파되므로 zone 미처리 예외로 새어 나갔다.
      final uncaught = <Object>[];
      final reported = <Object>[];
      final signals = StreamController<void>.broadcast();
      final claim = PangleClaimModel(
        reference: const AdRewardReference(
          type: AdRewardReferenceType.pangleClaim,
          id: 'claim-a',
        ),
        platform: 'android',
        signedToken: 'token',
        expiresAt: DateTime.utc(2030),
      );
      PangleClaimPreflightResult? result;
      await runZonedGuarded(() async {
        result =
            await PangleClaimPreflight(
              createClaim:
                  ({
                    required platform,
                    required placementId,
                    required clientRequestId,
                  }) async => claim,
              persist: (_, _) async {},
              pollingSignals: signals.stream,
              poll: (_, _) => throw StateError('ref used after dispose'),
              load: (_, _) async => true,
              onPollError: (error, _) => reported.add(error),
            ).execute(
              ownerUserId: 'user-a',
              platform: 'android',
              placementId: 'placement',
              clientRequestId: 'request',
            );
        signals.add(null);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }, (error, stackTrace) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(reported.single, isStateError);
      await result?.subscription.cancel();
      await signals.close();
    },
  );

  test('execute cancels its polling subscription when aborted during load', () async {
    // 구독은 execute 내부에서 만들어지고 호출부에는 반환 후에야 전달된다.
    // load 를 기다리는 동안 플랫폼이 dispose 되면 호출부의 dispose 는 이미
    // 지나갔으므로, execute 자신이 중단 여부를 보고 구독을 정리해야 한다.
    final signals = StreamController<void>.broadcast();
    var polls = 0;
    var aborted = false;
    final claim = PangleClaimModel(
      reference: const AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      ),
      platform: 'android',
      signedToken: 'token',
      expiresAt: DateTime.utc(2030),
    );
    final result =
        await PangleClaimPreflight(
          createClaim:
              ({
                required platform,
                required placementId,
                required clientRequestId,
              }) async => claim,
          persist: (_, _) async {},
          pollingSignals: signals.stream,
          poll: (_, _) async => polls++,
          load: (_, _) async {
            aborted = true;
            return true;
          },
          isAborted: () => aborted,
        ).execute(
          ownerUserId: 'user-a',
          platform: 'android',
          placementId: 'placement',
          clientRequestId: 'request',
        );
    expect(signals.hasListener, isFalse);
    signals.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(polls, 0);
    await result.subscription.cancel();
    await signals.close();
  });

  test('listener stops polling once aborted even if the subscription leaks', () async {
    final signals = StreamController<void>.broadcast();
    var polls = 0;
    var aborted = false;
    final claim = PangleClaimModel(
      reference: const AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      ),
      platform: 'android',
      signedToken: 'token',
      expiresAt: DateTime.utc(2030),
    );
    final result =
        await PangleClaimPreflight(
          createClaim:
              ({
                required platform,
                required placementId,
                required clientRequestId,
              }) async => claim,
          persist: (_, _) async {},
          pollingSignals: signals.stream,
          poll: (_, _) async => polls++,
          load: (_, _) async => true,
          isAborted: () => aborted,
        ).execute(
          ownerUserId: 'user-a',
          platform: 'android',
          placementId: 'placement',
          clientRequestId: 'request',
        );
    signals.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(polls, 1);
    aborted = true;
    signals.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(polls, 1);
    await result.subscription.cancel();
    await signals.close();
  });

  group('PangleClaimModel.mediaExtra 플랫폼 표기', () {
    // 프로덕션 결함 (2026-07-29 ~ 2026-08-13, PICNIC-2377):
    // ad-reward-claim 엣지 함수가 platform 을 toUpperCase() 해서 저장·응답하는데
    // (`'android'` → `'ANDROID'`), 네이티브 검증기는 소문자 정확 일치를 요구한다.
    //   Android: require(parts[1] == "android")
    //   iOS    : parts[1] == "ios"
    // 그래서 mediaExtra 가 `<uid>,ANDROID,v2.<token>` 이 되어 로드가 전부
    // "Signed v2 mediaExtra is required" 로 거부됐다. 사용자에겐 "모든 광고
    // 소진" 으로 보였다 — 클레임 1,452건에 지급 0건.
    //
    // 기존 테스트는 픽스처를 소문자로 만들어 이 경로를 한 번도 밟지 않았다.
    PangleClaimModel claimWith(String platform) => PangleClaimModel(
      reference: AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      ),
      platform: platform,
      signedToken: 'signed-token',
      expiresAt: DateTime.utc(2030),
    );

    test('서버가 대문자로 돌려줘도 네이티브 계약대로 소문자로 조립한다', () {
      expect(
        claimWith('ANDROID').mediaExtra('user-a'),
        'user-a,android,v2.signed-token',
      );
      expect(
        claimWith('IOS').mediaExtra('user-a'),
        'user-a,ios,v2.signed-token',
      );
    });

    test('이미 소문자면 그대로 둔다', () {
      expect(
        claimWith('android').mediaExtra('user-a'),
        'user-a,android,v2.signed-token',
      );
    });
  });
}
