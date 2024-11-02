// lib/components/vote/media/webview/video_webview_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.youtube.com/embed/$videoId'),
      ),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: true,
          useShouldOverrideUrlLoading: true,
        ),
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
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
