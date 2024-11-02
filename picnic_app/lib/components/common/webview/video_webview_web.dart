// lib/components/vote/media/webview/video_webview_web.dart

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'video_webview_interface.dart';

class WebWebViewProvider implements WebViewProvider {
  final String videoId;
  final LoadingCallback onLoadingChanged;
  final ProgressCallback onProgressChanged;
  late final String _viewId;
  html.IFrameElement? _iframeElement;
  bool _isRegistered = false;

  WebWebViewProvider({
    required this.videoId,
    required this.onLoadingChanged,
    required this.onProgressChanged,
  }) {
    _viewId =
        'youtube-player-$videoId-${DateTime.now().millisecondsSinceEpoch}';
    _setup();
  }

  void _setup() {
    if (_isRegistered) return;

    _iframeElement = html.IFrameElement()
      ..src = 'https://www.youtube.com/embed/$videoId'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..allowFullscreen = true;

    // Register view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement!,
    );
    _isRegistered = true;

    _iframeElement!.onLoad.listen((event) {
      onLoadingChanged(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: ValueKey(_viewId),
      viewType: _viewId,
    );
  }

  @override
  void dispose() {
    if (_iframeElement != null) {
      _iframeElement!.remove();
      _iframeElement = null;
    }
    _isRegistered = false;
  }
}

WebViewProvider createWebViewProvider({
  required String videoId,
  required LoadingCallback onLoadingChanged,
  required ProgressCallback onProgressChanged,
}) {
  return WebWebViewProvider(
    videoId: videoId,
    onLoadingChanged: onLoadingChanged,
    onProgressChanged: onProgressChanged,
  );
}
