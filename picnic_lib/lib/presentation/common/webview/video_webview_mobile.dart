// lib/components/vote/media/webview/video_webview_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';

import 'video_webview_interface.dart';

class MobileWebViewProvider implements WebViewProvider {
  final String videoId;
  final LoadingCallback onLoadingChanged;
  final ProgressCallback onProgressChanged;
  InAppWebViewController? _controller;

  MobileWebViewProvider({
    required this.videoId,
    required this.onLoadingChanged,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PrivacyConsentManager.canShowPersonalizedAds(),
      builder: (context, snapshot) {
        final canTrack = snapshot.data ?? false;

        return InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://www.youtube.com/embed/$videoId'),
            headers: {
              if (!canTrack) ...{
                'DNT': '1', // Do Not Track
                'Sec-GPC': '1', // Global Privacy Control
              },
            },
          ),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            transparentBackground: true,
            useShouldOverrideUrlLoading: true,
            // ATT 거부 시 쿠키/추적 제한
            thirdPartyCookiesEnabled: canTrack,
            // 추적 거부 시 캐시 사용 안함
            cacheEnabled: canTrack,
            // 개인정보 보호 강화
            incognito: !canTrack,
            // 추적 거부 시 localStorage 제한
            javaScriptEnabled: true,
            domStorageEnabled: canTrack,
          ),
          onWebViewCreated: (controller) async {
            _controller = controller;
            if (!canTrack) {
              await controller.evaluateJavascript(source: '''
                // 추적 스크립트 비활성화
                window.doNotTrack = "1";
                navigator.globalPrivacyControl = true;
                
                // 로컬 스토리지 비활성화
                localStorage.clear();
                Object.defineProperty(window, 'localStorage', {
                  value: null,
                  writable: false
                });
              ''');
            }
          },
          onLoadStart: (controller, url) {
            onLoadingChanged(true);
          },
          onProgressChanged: (controller, progress) {
            onProgressChanged(progress / 100);
          },
          onLoadStop: (controller, url) {
            onLoadingChanged(false);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString() ?? '';
            if (url.startsWith('https://www.youtube.com/')) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
  }
}

// 팩토리 함수 정의
WebViewProvider createWebViewProvider({
  required String videoId,
  required LoadingCallback onLoadingChanged,
  required ProgressCallback onProgressChanged,
}) {
  return MobileWebViewProvider(
    videoId: videoId,
    onLoadingChanged: onLoadingChanged,
    onProgressChanged: onProgressChanged,
  );
}
