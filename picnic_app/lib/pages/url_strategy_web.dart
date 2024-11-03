import 'dart:html' as html;

void clearUrlParameters() {
  try {
    final currentUrl = Uri.parse(html.window.location.href);
    final baseUrl =
        '${currentUrl.scheme}://${currentUrl.host}${currentUrl.path}';
    html.window.history.pushState({}, '', baseUrl);
  } catch (e) {
    print('Error clearing URL parameters: $e');
  }
}
