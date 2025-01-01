// lib/components/vote/media/webview/video_webview_stub.dart

import 'video_webview_interface.dart';

WebViewProvider createWebViewProvider({
  required String videoId,
  required LoadingCallback onLoadingChanged,
  required ProgressCallback onProgressChanged,
}) {
  throw UnsupportedError(
    'Cannot create a WebViewProvider without dart:html or dart:io',
  );
}
