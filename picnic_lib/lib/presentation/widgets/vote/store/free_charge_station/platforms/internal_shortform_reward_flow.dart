import 'dart:async';

import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

class InternalShortformIssueResult {
  const InternalShortformIssueResult({
    required this.ownerUserId,
    required this.reference,
    required this.videoUrl,
    required this.ctaUrl,
    required this.viewToken,
    this.moreToken,
  });
  final String ownerUserId;
  final AdRewardReference reference;
  final String videoUrl;
  final String? ctaUrl;
  final String viewToken;

  /// '더보기' 클릭을 서버에 기록할 때 쓰는 토큰.
  ///
  /// 재생·보상에는 관여하지 않는 통계용이라 없어도 광고는 정상 재생된다.
  /// (어드민 캠페인 리포트의 `more_clicks` 만 비게 된다.)
  final String? moreToken;
}

class InternalShortformIssueFlow {
  InternalShortformIssueFlow({
    required this.currentOwner,
    required this.invokeIssue,
    required this.persist,
    required this.rewriteVideoUrl,
  });
  static final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  final String? Function() currentOwner;
  final Future<Object?> Function() invokeIssue;
  final Future<void> Function(String, AdRewardReference) persist;
  final String Function(String?) rewriteVideoUrl;

  Future<InternalShortformIssueResult> issue() async {
    final owner = currentOwner();
    if (owner == null) {
      throw StateError('Authenticated user required for ad reward issue');
    }
    final raw = await invokeIssue();
    final result = _parse(owner, raw);
    await persist(owner, result.reference);
    return result;
  }

  InternalShortformIssueResult _parse(String owner, Object? raw) {
    try {
      if (raw is! Map) throw const FormatException('Invalid ad issue response');
      final body = Map<String, dynamic>.from(raw);
      final impressionId = body['impression_id'];
      if (impressionId is! String || !uuidPattern.hasMatch(impressionId)) {
        throw const FormatException('Invalid ad issue impression_id');
      }
      final ad = Map<String, dynamic>.from(body['ad'] as Map);
      final tokens = Map<String, dynamic>.from(body['tokens'] as Map);
      final videoUrl = rewriteVideoUrl(ad['video_url'] as String?);
      final viewToken = tokens['view_token'];
      if (videoUrl.isEmpty || viewToken is! String || viewToken.isEmpty) {
        throw const FormatException('Ad issue is not playable');
      }
      final rawMoreToken = tokens['more_token'];
      final moreToken = rawMoreToken is String && rawMoreToken.isNotEmpty
          ? rawMoreToken
          : null;
      final reference = AdRewardReference(
        type: AdRewardReferenceType.internalImpression,
        id: impressionId,
      );
      return InternalShortformIssueResult(
        ownerUserId: owner,
        reference: reference,
        videoUrl: videoUrl,
        ctaUrl: ad['cta_url'] as String?,
        viewToken: viewToken,
        moreToken: moreToken,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid ad issue response', error);
    }
  }
}

/// '더보기' 클릭을 `callback-ad-shortform-more` 에 기록한다.
///
/// 어드민 "광고 캠페인 월간" 리포트의 `more_clicks` 는
/// `ad_impressions.more_completed_at` 을 세는데, 앱이 이 콜백을 부르지 않아
/// 프로덕션 임프레션 전건이 NULL 이었다.
///
/// 보상이 아니라 통계다. 사용자는 이미 광고주 랜딩으로 떠나는 중이므로 실패해도
/// 화면에 올리지 않고 [onError] 로만 흘린다 — 이 쓰기가 CTA 이동이나 시청 보상을
/// 막는 일은 없어야 한다. 서버는 멱등하므로 중복 호출도 안전하다.
class InternalShortformMoreClickFlow {
  InternalShortformMoreClickFlow({
    required this.moreToken,
    required this.issuedOwner,
    required this.currentOwner,
    required this.invokeCallback,
    this.onError,
  });

  final String? moreToken;
  final String? issuedOwner;
  final String? Function() currentOwner;
  final Future<Object?> Function(String token) invokeCallback;
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// 서버에 클릭을 보냈으면 true. 보낼 토큰이 없거나 실패하면 false.
  Future<bool> report() async {
    final token = moreToken;
    if (token == null || token.isEmpty) return false;
    // 발급 이후 계정이 바뀌었으면 남의 세션으로 남의 토큰을 보내는 셈이라 보내지
    // 않는다 (시청 콜백과 같은 규칙).
    final owner = currentOwner();
    if (issuedOwner == null || owner == null || owner != issuedOwner) {
      return false;
    }
    try {
      // Future.sync: invokeCallback 이 동기로 던져도(예: dispose 된 ref.read)
      // 예외가 CTA 이동 경로로 새지 않게 한다.
      await Future.sync(() => invokeCallback(token));
      return true;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      return false;
    }
  }
}

class InternalShortformViewFlow {
  InternalShortformViewFlow({
    required this.session,
    required this.currentOwner,
    required this.invokeCallback,
    required this.parse,
  });
  final InternalShortformRewardSession session;
  final String? Function() currentOwner;
  final Future<Object?> Function() invokeCallback;
  final InternalShortformViewResponse Function(Map<String, dynamic>) parse;

  Future<InternalShortformViewResponse> report() async {
    final issuedOwner = session.ownerUserId;
    final owner = currentOwner();
    if (issuedOwner == null || owner == null || owner != issuedOwner) {
      throw StateError('Ad reward owner changed before view callback');
    }
    final raw = await invokeCallback();
    try {
      if (raw is! Map) {
        throw const FormatException('Invalid view callback response');
      }
      final response = parse(Map<String, dynamic>.from(raw));
      session.validateCallback(
        currentOwner: currentOwner(),
        response: response,
      );
      return response;
    } on FormatException {
      rethrow;
    } on TypeError catch (error) {
      throw FormatException('Invalid view callback response', error);
    }
  }
}

class InternalShortformViewRecoveryFlow {
  InternalShortformViewRecoveryFlow({
    required this.view,
    required this.poll,
    this.onPollError,
  });

  final InternalShortformViewFlow view;
  final Future<void> Function(String ownerUserId, AdRewardReference reference)
  poll;
  final void Function(Object error, StackTrace stackTrace)? onPollError;

  Future<InternalShortformViewResponse> report() async {
    final response = await view.report();
    // A synchronously granted reward is presented by the fullscreen page while
    // the ad is still open. Starting recovery here races that local receipt and
    // delays it until the route has been dismissed.
    if (response.reward == null ||
        response.reward!.state == AdRewardState.granted) {
      return response;
    }
    final owner = view.session.ownerUserId!;
    final reference = view.session.reference!;
    // Future.sync: dispose 된 ref.read 처럼 poll 이 동기로 던져도 시청 응답을
    // 잃지 않고 onPollError 로 모은다.
    unawaited(
      Future.sync(() => poll(owner, reference)).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        onPollError?.call(error, stackTrace);
      }),
    );
    return response;
  }
}
