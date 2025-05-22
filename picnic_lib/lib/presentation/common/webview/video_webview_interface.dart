// lib/components/vote/media/webview/video_webview_interface.dart

import 'package:flutter/material.dart';

abstract class WebViewProvider {
  Widget build(BuildContext context);

  void dispose();
}

typedef LoadingCallback = void Function(bool isLoading);
typedef ProgressCallback = void Function(double progress);

// 팩토리 인터페이스 제거 - 실제 구현은 stub/web/mobile에서 처리
