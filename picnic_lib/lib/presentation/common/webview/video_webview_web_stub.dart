// 웹이 아닌 플랫폼을 위한 stub 구현
import 'video_webview_interface.dart';

WebViewProvider createWebViewProvider({
  required String videoId,
  required LoadingCallback onLoadingChanged,
  required ProgressCallback onProgressChanged,
}) {
  throw UnsupportedError('웹 전용 기능입니다');
}
