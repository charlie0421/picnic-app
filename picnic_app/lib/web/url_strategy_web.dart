import 'package:web/web.dart' as web;
import 'package:picnic_lib/core/utils/logger.dart';

void clearUrlParameters() {
  try {
    final currentUrl = Uri.parse(web.window.location.href);
    final baseUrl =
        '${currentUrl.scheme}://${currentUrl.host}${currentUrl.path}';
    web.window.history.pushState(null, '', baseUrl);
  } catch (e, s) {
    logger.e('exception:', error: e, stackTrace: s);
    rethrow;
  }
}
