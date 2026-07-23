import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

class InternalShortformIssueResult {
  const InternalShortformIssueResult({
    required this.ownerUserId,
    required this.reference,
    required this.videoUrl,
    required this.ctaUrl,
    required this.viewToken,
    required this.moreToken,
  });
  final String ownerUserId;
  final AdRewardReference reference;
  final String videoUrl;
  final String? ctaUrl;
  final String viewToken;
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
        moreToken: tokens['more_token'] as String?,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid ad issue response', error);
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
