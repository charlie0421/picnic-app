// lib/platform_web.dart
// 이 파일은 non-web 플랫폼을 위한 스텁입니다.

// window와 history를 위한 더미 구현
class Window {
  String get location => '';

  History get history => History();
}

class History {
  void replaceState(Object? data, String title, String? url) {}
}

class Html {
  Window get window => Window();
}

final html = Html();
