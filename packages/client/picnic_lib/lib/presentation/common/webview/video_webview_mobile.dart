// lib/components/vote/media/webview/video_webview_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:picnic_lib/ui/style.dart';

import 'video_webview_interface.dart';

class MobileWebViewProvider implements WebViewProvider {
  final String videoId;
  final LoadingCallback onLoadingChanged;
  final ProgressCallback onProgressChanged;
  InAppWebViewController? _controller;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);

  MobileWebViewProvider({
    required this.videoId,
    required this.onLoadingChanged,
    required this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrackingStatus>(
      future: AppTrackingTransparency.trackingAuthorizationStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            constraints: const BoxConstraints(
              minHeight: 200,
              maxHeight: 400,
            ),
            color: AppColors.grey00,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary500,
                strokeWidth: 3,
              ),
            ),
          );
        }
        
        return Container(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 400,
          ),
          color: AppColors.grey00,
          child: Stack(
            children: [
              Container(
                color: AppColors.grey00,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: snapshot.data == TrackingStatus.authorized
                        ? WebUri('https://www.youtube.com/embed/$videoId?playsinline=0&fs=1&enablejsapi=1')
                        : WebUri('https://www.youtube-nocookie.com/embed/$videoId?playsinline=0&fs=1&enablejsapi=1'),
                    headers: {
                      'DNT': '1',  // Do Not Track 헤더
                      'Sec-GPC': '1',  // Global Privacy Control
                    },
                  ),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    transparentBackground: true,
                    useShouldOverrideUrlLoading: true,
                    thirdPartyCookiesEnabled: false,
                    allowsInlineMediaPlayback: true,
                    iframeAllowFullscreen: true,
                    supportZoom: false,
                    useHybridComposition: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    cacheEnabled: false,
                    javaScriptEnabled: true,
                    incognito: true,
                    applicationNameForUserAgent: '',
                    preferredContentMode: UserPreferredContentMode.RECOMMENDED,
                    allowsLinkPreview: false,
                    sharedCookiesEnabled: false,
                    safeBrowsingEnabled: false,
                    disableDefaultErrorPage: true,
                    useOnDownloadStart: false,
                    useShouldInterceptAjaxRequest: false,
                    useShouldInterceptFetchRequest: false,
                  ),
                  onWebViewCreated: (controller) async {
                    _controller = controller;
                    _isLoading.value = true;
                    await controller.setSettings(
                      settings: InAppWebViewSettings(
                        userAgent: 'Mozilla/5.0',
                      ),
                    );
                  },
                  onLoadStart: (controller, url) {
                    onLoadingChanged(true);
                  },
                  onProgressChanged: (controller, progress) {
                    onProgressChanged(progress / 100);
                    if (progress >= 100) {
                      _isLoading.value = false;
                    }
                  },
                  onLoadStop: (controller, url) {
                    onLoadingChanged(false);
                    _isLoading.value = false;
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url?.toString() ?? '';
                    if (url.startsWith('https://www.youtube.com/')) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    return NavigationActionPolicy.CANCEL;
                  },
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, isLoading, child) {
                  return isLoading
                      ? Container(
                          color: AppColors.grey00.withOpacity(0.5),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary500,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _controller?.dispose();
    InAppWebViewController.clearAllCache();
    CookieManager.instance().deleteAllCookies();
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
