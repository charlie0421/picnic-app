// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:picnic_lib/core/utils/logger.dart';

void clearUrlParameters() {
  try {
    final currentUrl = Uri.parse(html.window.location.href);
    final baseUrl =
        '${currentUrl.scheme}://${currentUrl.host}${currentUrl.path}';
    html.window.history.pushState({}, '', baseUrl);
  } catch (e, s) {
    logger.e('exception:', error: e, stackTrace: s);
    rethrow;
  }
}
