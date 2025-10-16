// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:video_player/video_player.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

class ShortformInternalPlatform extends AdPlatform {
  ShortformInternalPlatform(
    super.ref,
    super.context,
    super.id,
    AnimationController super.animationController,
  );

  String? _viewToken;
  String? _moreToken;
  String? _videoUrl;
  String? _ctaUrl;
  VideoPlayerController? _controller;
  bool _issued = false;
  bool _viewCalled = false;

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

  Future<void> _issue() async {
    if (_issued) return;
    try {
      final supabaseUrl = Environment.supabaseUrl;
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final res = await supabase.auth.currentSession != null
          ? await SupabaseClient(
              supabaseUrl,
              Environment.supabaseAnonKey,
            ).functions.invoke(
              'ad-shortform-issue',
              headers: {'Authorization': 'Bearer $token'},
            )
          : throw Exception('not logged in');
      if (res.data == null) throw Exception('issue failed');
      final json = res.data as Map<String, dynamic>;
      final ad = json['ad'] as Map<String, dynamic>?;
      final tokens = json['tokens'] as Map<String, dynamic>?;
      _videoUrl = ad?['video_url'] as String?;
      _ctaUrl = ad?['cta_url'] as String?;
      logInfo('issued video_url: ${_videoUrl ?? ''}');
      logInfo('issued cta_url: ${_ctaUrl ?? ''}');
      _viewToken = tokens?['view_token'] as String?;
      _moreToken = tokens?['more_token'] as String?;
      _issued = true;
    } catch (e, s) {
      logError('issue failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _play() async {
    try {
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => AdShortformFullscreenPage(
            videoUrl: _videoUrl ?? '',
            ctaUrl: _ctaUrl,
            onViewComplete: () async {
              await _callView();
            },
            onMore: () async {
              await _callMore();
            },
            loadAd: () async {
              // 라우트 진입 시점에 최신 광고/토큰 발급 (만료 최소화)
              logInfo('loadAd: issuing new tokens');
              final supabaseUrl = Environment.supabaseUrl;
              final token = supabase.auth.currentSession?.accessToken ?? '';
              final res =
                  await SupabaseClient(
                    supabaseUrl,
                    Environment.supabaseAnonKey,
                  ).functions.invoke(
                    'ad-shortform-issue',
                    headers: {'Authorization': 'Bearer $token'},
                  );
              if (res.data == null) {
                throw Exception('issue failed');
              }
              final json = res.data as Map<String, dynamic>;
              final ad = json['ad'] as Map<String, dynamic>?;
              final tokens = json['tokens'] as Map<String, dynamic>?;
              _videoUrl = ad?['video_url'] as String?;
              _ctaUrl = ad?['cta_url'] as String?;
              logInfo('issued (route) video_url: ${_videoUrl ?? ''}');
              _viewToken = tokens?['view_token'] as String?;
              _moreToken = tokens?['more_token'] as String?;
              _issued = true;
              return (videoUrl: _videoUrl ?? '', ctaUrl: _ctaUrl);
            },
          ),
          transitionsBuilder: (_, a, __, child) =>
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
      final res = await SupabaseClient(supabaseUrl, Environment.supabaseAnonKey)
          .functions
          .invoke(
            'ad-shortform-issue',
            headers: {'Authorization': 'Bearer $token'},
          );
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
      logError('reissue failed', error: e, stackTrace: s);
    }
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

  Future<void> _callView() async {
    if ((_viewToken ?? '').isEmpty) return;
    try {
      logInfo('callView start');
      final supabaseUrl = Environment.supabaseUrl;
      final token = supabase.auth.currentSession?.accessToken ?? '';
      final client = SupabaseClient(supabaseUrl, Environment.supabaseAnonKey);
      await client.functions.invoke(
        'callback-ad-shortform-view',
        headers: {'Authorization': 'Bearer $token'},
        body: {'token': _viewToken},
      );
      logInfo('callView success');
      commonUtils.refreshUserProfile();
    } catch (e, s) {
      // 만료 시 1회 재발급 후 재시도
      final msg = e.toString().toLowerCase();
      if (msg.contains('expired') || msg.contains('bad request')) {
        try {
          logWarning('callView expired -> reissue & retry');
          await _reissueTokens();
          final supabaseUrl = Environment.supabaseUrl;
          final token = supabase.auth.currentSession?.accessToken ?? '';
          final client = SupabaseClient(
            supabaseUrl,
            Environment.supabaseAnonKey,
          );
          await client.functions.invoke(
            'callback-ad-shortform-view',
            headers: {'Authorization': 'Bearer $token'},
            body: {'token': _viewToken},
          );
          logInfo('callView retry success');
          commonUtils.refreshUserProfile();
          return;
        } catch (e2, s2) {
          logError('view failed (retry)', error: e2, stackTrace: s2);
        }
      }
      logError('view failed', error: e, stackTrace: s);
    }
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
