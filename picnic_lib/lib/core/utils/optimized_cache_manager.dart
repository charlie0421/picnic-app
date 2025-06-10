import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:universal_platform/universal_platform.dart';

/// PicnicApp에 최적화된 캐시 관리자
///
/// 특징:
/// - 향상된 HTTP 헤더로 캐싱 최적화
/// - 재시도 로직이 포함된 HTTP 클라이언트 사용
/// - 플랫폼별 캐시 설정 최적화
/// - 메모리 및 디스크 캐시 크기 조정
class OptimizedCacheManager extends CacheManager with ImageCacheManager {
  static const String _cacheKey = 'picnic_optimized_cache';

  static OptimizedCacheManager? _instance;

  /// 싱글톤 인스턴스 반환
  static OptimizedCacheManager get instance {
    _instance ??= OptimizedCacheManager._();
    return _instance!;
  }

  OptimizedCacheManager._()
      : super(
          Config(
            _cacheKey,
            stalePeriod: const Duration(days: 30), // 30일 동안 캐시 유지
            maxNrOfCacheObjects: 1000, // 최대 1000개 캐시 객체
            repo: JsonCacheInfoRepository(databaseName: _cacheKey),
            fileSystem: IOFileSystem(_cacheKey),
            fileService: OptimizedHttpFileService(),
          ),
        );

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    // 최적화된 헤더 추가
    final optimizedHeaders = <String, String>{
      ...?headers,
      ..._getOptimizedHeaders(),
    };

    return super.getFileStream(
      url,
      key: key,
      headers: optimizedHeaders,
      withProgress: withProgress,
    );
  }

  /// 플랫폼별 최적화된 HTTP 헤더 반환
  Map<String, String> _getOptimizedHeaders() {
    final baseHeaders = <String, String>{
      'Accept': 'image/webp,image/avif,image/apng,image/*,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'public, max-age=31536000, immutable',
      'Pragma': 'public',
      'User-Agent': 'PicnicApp/1.0 (Mobile; ${_getPlatformInfo()})',
    };

    // 네이티브 환경에서만 연결 관련 헤더 추가
    if (!UniversalPlatform.isWeb) {
      baseHeaders.addAll({
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=60, max=1000',
        'Accept-Charset': 'utf-8',
        'DNT': '1', // Do Not Track
      });
    }

    return baseHeaders;
  }

  String _getPlatformInfo() {
    if (UniversalPlatform.isIOS) return 'iOS';
    if (UniversalPlatform.isAndroid) return 'Android';
    if (UniversalPlatform.isWeb) return 'Web';
    if (UniversalPlatform.isMacOS) return 'macOS';
    if (UniversalPlatform.isWindows) return 'Windows';
    if (UniversalPlatform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

/// 최적화된 HTTP 파일 서비스
///
/// RetryHttpClient를 사용하여 네트워크 안정성 향상
class OptimizedHttpFileService extends HttpFileService {
  static http.Client? _httpClient;

  @override
  http.Client get httpClient {
    _httpClient ??= RetryHttpClient(
      http.Client(),
      maxAttempts: 3,
      timeout: const Duration(seconds: 30),
      keepAlive: const Duration(seconds: 60),
    );
    return _httpClient!;
  }

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    // CDN 특화 헤더 추가
    final optimizedHeaders = <String, String>{
      ...?headers,
      'X-Forwarded-Proto': 'https',
      'X-Requested-With': 'PicnicApp',
      'Sec-Fetch-Dest': 'image',
      'Sec-Fetch-Mode': 'no-cors',
      'Sec-Fetch-Site': 'cross-site',
    };

    return super.get(url, headers: optimizedHeaders);
  }
}
