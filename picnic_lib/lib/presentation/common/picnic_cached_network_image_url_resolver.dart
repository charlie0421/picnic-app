/// Resolves image keys into the URL requested by `PicnicCachedNetworkImage`.
///
/// Relative keys and absolute URLs on the configured CDN origin are
/// first-party: they are always requested at one fixed CDN width. Legacy
/// `http://` URLs for the same CDN host on the default port are moved to the
/// configured HTTPS origin first. External HTTP(S) URLs are preserved so signed
/// queries remain valid, and protocol-relative URLs are promoted to HTTPS.
final class PicnicCachedNetworkImageUrlResolver {
  const PicnicCachedNetworkImageUrlResolver({required this.cdnUrl});

  final String? cdnUrl;

  /// Resolves [imageUrl] to one fixed CDN variant: `q` then `w`, never `h`.
  ///
  /// Every device must receive the same variant, so callers pass constants,
  /// not layout- or DPR-derived pixels. Without a height the CDN keeps the
  /// source ratio. External URLs are returned unchanged.
  String resolveFixedWidth(
    String imageUrl, {
    required int width,
    required int quality,
  }) {
    RangeError.checkValueInInterval(width, 1, 1 << 30, 'width');
    RangeError.checkValueInInterval(quality, 1, 100, 'quality');
    final firstParty = _firstPartyUri(imageUrl);
    if (firstParty == null) return _preservedExternalUrl(imageUrl);

    // replace intentionally drops every existing CDN query parameter. The
    // production resizer contract uses only q/w/h; fragments remain intact.
    return firstParty
        .replace(queryParameters: {'q': '$quality', 'w': '$width'})
        .toString();
  }

  /// The CDN URI for relative keys and same-origin absolute URLs, or null for
  /// an external HTTP(S) URL.
  Uri? _firstPartyUri(String imageUrl) {
    final normalizedImageUrl = imageUrl.trim();
    final classified = _classifyImageKey(normalizedImageUrl);

    if (classified.isAbsolute) {
      final uri = classified.uri!;
      return _isCdnUrl(uri) ? uri : _legacyHttpCdnUri(uri);
    }

    final cdnUrl = this.cdnUrl;
    if (cdnUrl == null) {
      throw StateError('CDN URL is required for relative image URLs.');
    }
    return Uri.parse(
      '$cdnUrl/${normalizedImageUrl.startsWith('/') ? normalizedImageUrl.substring(1) : normalizedImageUrl}',
    );
  }

  /// The configured HTTPS origin for a legacy `http://` spelling of the same
  /// CDN host on the default port, or null. Other ports stay separate origins,
  /// and URLs carrying credentials are never rewritten.
  Uri? _legacyHttpCdnUri(Uri uri) {
    final cdnUrl = this.cdnUrl;
    if (cdnUrl == null) return null;
    final cdnUri = Uri.parse(cdnUrl);
    if (uri.scheme.toLowerCase() != 'http' ||
        cdnUri.scheme.toLowerCase() != 'https' ||
        uri.port != 80 ||
        cdnUri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        _normalizeHost(uri.host) != _normalizeHost(cdnUri.host)) {
      return null;
    }
    return uri.replace(
      scheme: cdnUri.scheme,
      host: cdnUri.host,
      port: cdnUri.port,
    );
  }

  String _preservedExternalUrl(String imageUrl) {
    final normalizedImageUrl = imageUrl.trim();
    // External HTTP(S) URLs must keep signed queries and their original
    // spelling. A protocol-relative URL is the sole exception because it
    // needs an HTTPS scheme before CachedNetworkImage can fetch it.
    return normalizedImageUrl.startsWith('//')
        ? _classifyImageKey(normalizedImageUrl).uri!.toString()
        : normalizedImageUrl;
  }

  ({bool isAbsolute, Uri? uri}) _classifyImageKey(String normalizedImageUrl) {
    if (normalizedImageUrl.isEmpty) {
      return (isAbsolute: false, uri: null);
    }

    // Only HTTP(S) authorities are network URLs here. Other schemes retain
    // the widget's historical relative-path behavior.
    final directUri = Uri.tryParse(normalizedImageUrl);
    if (directUri != null &&
        directUri.hasAuthority &&
        (directUri.scheme == 'http' || directUri.scheme == 'https')) {
      return (isAbsolute: true, uri: directUri);
    }

    if (normalizedImageUrl.startsWith('//')) {
      final promoted = Uri.tryParse('https:$normalizedImageUrl');
      if (promoted != null && promoted.hasAuthority) {
        return (isAbsolute: true, uri: promoted);
      }
    }

    return (isAbsolute: false, uri: null);
  }

  bool _isCdnUrl(Uri uri) {
    final cdnUrl = this.cdnUrl;
    if (cdnUrl == null) return false;
    final cdnUri = Uri.parse(cdnUrl);
    // The resize contract belongs to one origin, not every URL sharing its
    // host. Uri.port already normalizes omitted HTTP(S) default ports.
    return uri.userInfo.isEmpty &&
        uri.scheme.toLowerCase() == cdnUri.scheme.toLowerCase() &&
        _normalizeHost(uri.host) == _normalizeHost(cdnUri.host) &&
        uri.port == cdnUri.port;
  }

  String _normalizeHost(String host) {
    final lower = host.toLowerCase();
    // A trailing dot is only the DNS FQDN spelling of the same host.
    return lower.endsWith('.') ? lower.substring(0, lower.length - 1) : lower;
  }
}
