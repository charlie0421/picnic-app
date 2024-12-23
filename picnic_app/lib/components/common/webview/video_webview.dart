export 'video_webview_interface.dart';
// 각 플랫폼별 구현에서 제공하는 createWebViewProvider 함수를 직접 export
export 'video_webview_stub.dart'
    if (dart.library.html) 'video_webview_web.dart'
    if (dart.library.io) 'video_webview_mobile.dart' show createWebViewProvider;
