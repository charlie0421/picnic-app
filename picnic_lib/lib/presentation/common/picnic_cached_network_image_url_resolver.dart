/// A single CDN URL variant requested by [PicnicCachedNetworkImageUrlResolver].
final class PicnicCachedNetworkImageUrlVariant {
  const PicnicCachedNetworkImageUrlVariant({
    required this.resolutionMultiplier,
    required this.quality,
  });

  final double resolutionMultiplier;
  final int quality;
}

/// Resolves image keys into the ordered URLs requested by
/// `PicnicCachedNetworkImage`.
///
/// Relative keys and absolute URLs on the configured CDN origin receive the
/// CDN's `w`/`h`/`q` query. External HTTP(S) URLs are preserved so signed
/// queries remain valid, and protocol-relative URLs are promoted to HTTPS.
final class PicnicCachedNetworkImageUrlResolver {
  const PicnicCachedNetworkImageUrlResolver({required this.cdnUrl});

  final String? cdnUrl;

  List<String> resolve({
    required String imageUrl,
    required double? width,
    required double? height,
    required List<PicnicCachedNetworkImageUrlVariant> variants,
  }) {
    final normalizedImageUrl = imageUrl.trim();
    final classified = _classifyImageKey(normalizedImageUrl);

    if (classified.isAbsolute) {
      final uri = classified.uri!;
      if (!_isCdnUrl(uri)) {
        // External HTTP(S) URLs must keep signed queries and their original
        // spelling. A protocol-relative URL is the sole exception because it
        // needs an HTTPS scheme before CachedNetworkImage can fetch it.
        return [
          normalizedImageUrl.startsWith('//')
              ? uri.toString()
              : normalizedImageUrl,
        ];
      }

      return _resolveVariants(uri, width, height, variants);
    }

    final cdnUrl = this.cdnUrl;
    if (cdnUrl == null) {
      throw StateError('CDN URL is required for relative image URLs.');
    }
    final uri = Uri.parse(
      '$cdnUrl/${normalizedImageUrl.startsWith('/') ? normalizedImageUrl.substring(1) : normalizedImageUrl}',
    );
    return _resolveVariants(uri, width, height, variants);
  }

  List<String> _resolveVariants(
    Uri uri,
    double? width,
    double? height,
    List<PicnicCachedNetworkImageUrlVariant> variants,
  ) {
    return [
      for (final variant in variants)
        _withCdnQuery(uri, width, height, variant).toString(),
    ];
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
    return uri.scheme.toLowerCase() == cdnUri.scheme.toLowerCase() &&
        _normalizeHost(uri.host) == _normalizeHost(cdnUri.host) &&
        uri.port == cdnUri.port;
  }

  String _normalizeHost(String host) {
    final lower = host.toLowerCase();
    // A trailing dot is only the DNS FQDN spelling of the same host.
    return lower.endsWith('.') ? lower.substring(0, lower.length - 1) : lower;
  }

  Uri _withCdnQuery(
    Uri uri,
    double? width,
    double? height,
    PicnicCachedNetworkImageUrlVariant variant,
  ) {
    // replace intentionally drops every existing CDN query parameter. The
    // production resizer contract uses only q/w/h; fragments remain intact.
    final queryParameters = <String, String>{'q': variant.quality.toString()};

    if (width != null && width.isFinite) {
      queryParameters['w'] = _roundPixels(
        width,
        variant.resolutionMultiplier,
      ).toString();
    }
    if (height != null && height.isFinite) {
      queryParameters['h'] = _roundPixels(
        height,
        variant.resolutionMultiplier,
      ).toString();
    }

    return uri.replace(queryParameters: queryParameters);
  }

  int _roundPixels(double value, double multiplier) {
    final computed = (value * multiplier).round();
    return computed > 0 ? computed : 1;
  }
}
