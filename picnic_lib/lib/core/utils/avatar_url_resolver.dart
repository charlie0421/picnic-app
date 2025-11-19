import 'package:picnic_lib/core/utils/logger.dart';

/// Resolves avatar URLs into a safe, normalized string that can be passed to
/// image widgets.
///
/// The resolver is intentionally conservative: if the incoming value is `null`
/// or blank we immediately return an empty string so that callers can switch to
/// their fallback avatars without triggering network requests. We also trim the
/// value and normalise scheme-less URLs (e.g. `//example.com`) to https. Any
/// unexpected errors are captured in the shared logger but we still fall back to
/// an empty string to avoid crashes.
String resolveAvatarImageUrl(String? rawUrl) {
  if (rawUrl == null) {
    return '';
  }

  final cleaned = rawUrl.trim();
  if (cleaned.isEmpty) {
    return '';
  }

  try {
    if (cleaned.startsWith('//')) {
      return 'https:$cleaned';
    }

    return cleaned;
  } catch (error, stackTrace) {
    logger.e('Avatar URL resolve 실패', error: error, stackTrace: stackTrace);
    return '';
  }
}
