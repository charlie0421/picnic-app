// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:picnic_lib/presentation/widgets/anti_abuse/rate_limited_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:video_player/video_player.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

class ShortformInternalPlatform extends AdPlatform {
  ShortformInternalPlatform(
    super.ref,
    super.context,
    super.id,
    AnimationController super.animationController,
  );

  // 임시 HLS 마스터 URL 치환(ads/* 경로용) - ads 경로에서 파일명(UUID)을 추출해 동적 구성
  static const String _cloudfrontBase =
      'https://d2jrkjksiktw4e.cloudfront.net/picnic/videos/output';
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  @visibleForTesting
  String rewriteVideoUrlIfNeeded(String? url) {
    if (url == null || url.isEmpty) return '';
    final normalized = url.split('?').first.split('#').first;

    // 1) ads/* 경로 → UUID 추출 후 CloudFront master.m3u8로 치환
    final hasAds =
        normalized.startsWith('ads/') || normalized.contains('/ads/');
    if (hasAds) {
      final segments = normalized
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      String? id;
      for (final s in segments) {
        final part = s.contains('.') ? s.substring(0, s.lastIndexOf('.')) : s;
        if (_uuidPattern.hasMatch(part)) {
          id = part;
          break;
        }
      }
      id ??= () {
        final last = segments.isNotEmpty ? segments.last : '';
        return last.contains('.')
            ? last.substring(0, last.lastIndexOf('.'))
            : last;
      }();
      if (id.isEmpty) return url; // 추출 실패 시 원본 유지
      return '$_cloudfrontBase/$id/master.m3u8';
    }

    // 2) /videos/output/* 경로 → 받은 값의 ID를 기준으로 CloudFront master.m3u8 구성
    final pathOnly = () {
      final uri = Uri.tryParse(normalized);
      return uri?.path.isNotEmpty == true ? uri!.path : normalized;
    }();
    if (pathOnly.contains(RegExp(r'/videos/output/'))) {
      final segs = pathOnly.split('/').where((s) => s.isNotEmpty).toList();
      final idx = segs.indexWhere((s) => s == 'videos');
      if (idx != -1 && idx + 2 < segs.length && segs[idx + 1] == 'output') {
        var idSeg = segs[idx + 2];
        idSeg = idSeg.contains('.')
            ? idSeg.substring(0, idSeg.lastIndexOf('.'))
            : idSeg;
        if (idSeg.isNotEmpty) {
          return '$_cloudfrontBase/$idSeg/master.m3u8';
        }
      }
    }

    // 그 외에는 원본 유지
    return url;
  }

  String? _viewToken;
  String? _moreToken;
  String? _videoUrl;
  String? _ctaUrl;
  VideoPlayerController? _controller;
  bool _viewCalled = false;
  final _rewardSession = InternalShortformRewardSession();

  @override
  Future<void> initialize() async {
    // 별도 초기화 없음
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      startButtonAnimation();
      // 사전 발급은 생략하고 라우트 진입 시점에 최신 토큰 발급
      stopAllAnimations();
      await _play();
    }); // checkAdsLimit 수행 (기본값)
  }

  Future<void> _play() async {
    try {
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, _, _) => AdShortformFullscreenPage(
            videoUrl: _videoUrl ?? '',
            ctaUrl: _ctaUrl,
            onViewComplete: _callView,
            onMore: () async {
              await _callMore();
            },
            loadAd: () async {
              // 라우트 진입 시점에 최신 광고/토큰 발급 (만료 최소화)
              logInfo('loadAd: issuing new tokens');
              return _issueAdTokensFromRoute();
            },
          ),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e, s) {
      logError('play failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _reissueTokens() async {
    try {
      final supabaseUrl = Environment.supabaseUrl;
      final token = supabase.auth.currentSession?.accessToken ?? '';
      // Attach X-Device-Id for anti-abuse device-cohort signal.
      // Graceful: if retrieval fails the request proceeds without the header.
      final Map<String, String> reissueHeaders = {
        'Authorization': 'Bearer $token',
      };
      try {
        final deviceId = await DeviceManager.getDeviceId();
        reissueHeaders['X-Device-Id'] = deviceId;
      } catch (e) {
        logWarning(
          'Could not retrieve device ID for ad-shortform-issue reissue header: $e',
        );
      }
      final res = await SupabaseClient(
        supabaseUrl,
        Environment.supabaseAnonKey,
      ).functions.invoke('ad-shortform-issue', headers: reissueHeaders);
      if (res.data == null) throw Exception('issue failed');
      final json = res.data as Map<String, dynamic>;
      final ad = json['ad'] as Map<String, dynamic>?;
      final tokens = json['tokens'] as Map<String, dynamic>?;
      // 비디오/CTA가 바뀔 수도 있으나, 콜백만 재시도할 목적이면 토큰만 갱신
      _viewToken = tokens?['view_token'] as String?;
      _moreToken = tokens?['more_token'] as String?;
      if (ad != null) {
        _videoUrl = ad['video_url'] as String? ?? _videoUrl;
        _ctaUrl = ad['cta_url'] as String? ?? _ctaUrl;
      }
      logInfo('tokens reissued');
    } catch (e, s) {
      final aa = mapToAntiAbuseException(e);
      if (aa is AntiAbuseException) {
        logWarning(
          'ad-shortform-issue (reissue) blocked: channel=${aa.channel}',
        );
        _showRateLimitedAndCloseRoute(aa.channel);
        return;
      }
      logError('reissue failed', error: e, stackTrace: s);
    }
  }

  /// loadAd 경로 — anti-abuse 매핑 + token 추출 책임을 한 군데로 모음.
  /// anti-abuse 차단 시 fullscreen 라우트를 닫고 부모 context 에서 dialog 노출 후
  /// `blocked: true` 인 빈 결과를 반환한다. 그 외 실패(예: server 오류)는 rethrow 되어
  /// fullscreen 의 _initializeFlow 가 에러 다이얼로그를 띄운다. blocked 플래그로
  /// "anti-abuse 가 이미 pop 예약" vs "그냥 실패/빈값" 을 구분해 무한펄스를 막는다.
  Future<({String videoUrl, String? ctaUrl, bool blocked})>
  _issueAdTokensFromRoute() async {
    final ownerUserId = supabase.auth.currentUser?.id;
    if (ownerUserId == null) {
      throw StateError('Authenticated user required for ad reward issue');
    }
    final supabaseUrl = Environment.supabaseUrl;
    final token = supabase.auth.currentSession?.accessToken ?? '';
    // Attach X-Device-Id for anti-abuse device-cohort signal.
    // Graceful: if retrieval fails the request proceeds without the header.
    final Map<String, String> issueHeaders = {'Authorization': 'Bearer $token'};
    try {
      final deviceId = await DeviceManager.getDeviceId();
      issueHeaders['X-Device-Id'] = deviceId;
    } catch (e) {
      logWarning(
        'Could not retrieve device ID for ad-shortform-issue header: $e',
      );
    }
    try {
      final res = await SupabaseClient(
        supabaseUrl,
        Environment.supabaseAnonKey,
      ).functions.invoke('ad-shortform-issue', headers: issueHeaders);
      if (res.data is! Map) {
        throw const FormatException('Invalid ad issue response');
      }
      final json = Map<String, dynamic>.from(res.data as Map);
      final impressionId = json['impression_id'];
      if (impressionId is! String || !_uuidPattern.hasMatch(impressionId)) {
        throw const FormatException('Invalid ad issue impression_id');
      }
      final ad = Map<String, dynamic>.from(json['ad'] as Map);
      final tokens = Map<String, dynamic>.from(json['tokens'] as Map);
      _videoUrl = ad['video_url'] as String?;
      _ctaUrl = ad['cta_url'] as String?;
      // 임시: ads/* 또는 /video(s)/output/* 경로를 CloudFront HLS 마스터로 동적 치환
      _videoUrl = rewriteVideoUrlIfNeeded(_videoUrl);
      logInfo('issued (route) video_url: ${_videoUrl ?? ''}');
      _viewToken = tokens['view_token'] as String?;
      _moreToken = tokens['more_token'] as String?;
      if ((_videoUrl ?? '').isEmpty || (_viewToken ?? '').isEmpty) {
        throw const FormatException('Ad issue is not playable');
      }
      final reference = AdRewardReference(
        type: AdRewardReferenceType.internalImpression,
        id: impressionId,
      );
      await _rewardSession.bindIssued(
        owner: ownerUserId,
        issuedReference: reference,
        persist: ref.read(pendingAdRewardStoreProvider).add,
      );
      return (videoUrl: _videoUrl ?? '', ctaUrl: _ctaUrl, blocked: false);
    } catch (e) {
      final aa = mapToAntiAbuseException(e);
      if (aa is AntiAbuseException) {
        logWarning('ad-shortform-issue blocked: channel=${aa.channel}');
        _showRateLimitedAndCloseRoute(aa.channel);
        // anti-abuse 차단: route pop + rate-limited dialog 는 여기서 처리됨.
        // blocked:true 로 fullscreen 이 중복 에러 다이얼로그를 띄우지 않게 한다.
        return (videoUrl: '', ctaUrl: null, blocked: true);
      }
      // anti-abuse 가 아닌 실패는 rethrow → fullscreen 이 에러 다이얼로그 + pop.
      rethrow;
    }
  }

  /// fullscreen 라우트 close + 부모 context 에서 anti-abuse 다이얼로그 표시.
  void _showRateLimitedAndCloseRoute(String channel) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showRateLimitedDialog(context, channel: channel);
      }
    });
  }

  void _onProgress() {
    final v = _controller;
    if (v == null) return;
    if (!_viewCalled &&
        v.value.isInitialized &&
        v.value.position >= v.value.duration) {
      _viewCalled = true;
      _callView();
    }
  }

  Future<InternalShortformViewResponse> _callView() async {
    if (_rewardSession.reference == null) {
      throw StateError('No issued impression for view callback');
    }
    if ((_viewToken ?? '').isEmpty) {
      throw StateError('No issued view token');
    }
    final response = await supabase.functions.invoke(
      'callback-ad-shortform-view',
      body: {'token': _viewToken},
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid view callback response');
    }
    final parsed = ref
        .read(adRewardRepositoryProvider)
        .parseInternalViewResponse(
          Map<String, dynamic>.from(response.data as Map),
        );
    _rewardSession.validateCallback(
      currentOwner: supabase.auth.currentUser?.id,
      response: parsed,
    );
    return parsed;
  }

  Future<void> _callMore() async {
    if ((_moreToken ?? '').isEmpty) return;
    try {
      logInfo('callMore start');
      final supabaseUrl = Environment.supabaseUrl;
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final client = SupabaseClient(supabaseUrl, Environment.supabaseAnonKey);
      await client.functions.invoke(
        'callback-ad-shortform-more',
        headers: {'Authorization': 'Bearer $token'},
        body: {'token': _moreToken},
      );
      logInfo('callMore success');
      commonUtils.refreshUserProfile();
    } catch (e, s) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('expired') || msg.contains('bad request')) {
        try {
          logWarning('callMore expired -> reissue & retry');
          await _reissueTokens();
          final supabaseUrl = Environment.supabaseUrl;
          final token = supabase.auth.currentSession?.accessToken ?? '';
          final client = SupabaseClient(
            supabaseUrl,
            Environment.supabaseAnonKey,
          );
          await client.functions.invoke(
            'callback-ad-shortform-more',
            headers: {'Authorization': 'Bearer $token'},
            body: {'token': _moreToken},
          );
          logInfo('callMore retry success');
          commonUtils.refreshUserProfile();
          return;
        } catch (e2, s2) {
          logError('more failed (retry)', error: e2, stackTrace: s2);
        }
      }
      logError('more failed', error: e, stackTrace: s);
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logError('internal shortform error', error: error, stackTrace: stackTrace);
  }

  @override
  void dispose() {
    try {
      _controller?.removeListener(_onProgress);
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
