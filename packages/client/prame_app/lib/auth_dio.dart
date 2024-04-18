import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:prame_app/constants.dart';

Future<Dio> authDio({String baseUrl = Constants.userApiUrl}) async {
  var dio = Dio();

  dio.interceptors.clear();

  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    // 기기에 저장된 AccessToken 로드
    final accessToken = await globalStorage.loadData('ACCESS_TOKEN', '');
    final refreshToken = await globalStorage.loadData('REFRESH_TOKEN', '');

    if (kDebugMode) {
      logger.w('accessToken:${accessToken ?? 'no access token'}');
    }

    options.baseUrl = baseUrl;
    options.headers['Authorization'] = 'Bearer $accessToken';
    options.headers['Content-Type'] = 'application/json';

    if (kDebugMode) {
      logger.d(
          '${options.method} ${options.baseUrl}${options.path} ${options.queryParameters} ${options.data ?? ''}');
    }

    return handler.next(options);
  }, onError: (error, handler) async {
    logger.e(error);

    if (kDebugMode) {
      logger.d(
          '${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path} ${error.requestOptions.queryParameters} ${error.requestOptions.data ?? ''}');
    }

    if (error.response?.statusCode == 401) {
      final accessToken = await globalStorage.loadData('ACCESS_TOKEN', '');
      final refreshToken = await globalStorage.loadData('REFRESH_TOKEN', '');
      var refreshDio = Dio();

      refreshDio.interceptors.clear();

      refreshDio.interceptors
          .add(InterceptorsWrapper(onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await globalStorage.clearStorage();
        }
        return handler.next(error);
      }));

      refreshDio.options.baseUrl = Constants.authApiUrl;
      refreshDio.options.headers['Authorization'] = 'Bearer $accessToken';
      refreshDio.options.headers['Refresh'] = 'Bearer $refreshToken';

      final refreshResponse = await refreshDio
          .post('/refreshAccessToken', data: {'refreshToken': refreshToken});

      final newAccessToken = refreshResponse.data['accessToken'];
      final newRefreshToken = refreshResponse.data['refreshToken'];

      logger.w('newAccessToken: $newAccessToken');

      await globalStorage.saveData('ACCESS_TOKEN', newAccessToken);
      await globalStorage.saveData('REFRESH_TOKEN', newRefreshToken);

      error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final clonedRequest = await dio.request(error.requestOptions.path,
          options: Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers),
          data: error.requestOptions.data,
          queryParameters: error.requestOptions.queryParameters);

      if (kDebugMode) {
        logger.d(
            '${clonedRequest.requestOptions.method} ${clonedRequest.requestOptions.baseUrl}${clonedRequest.requestOptions.path} ${clonedRequest.requestOptions.data}');
      }

      return handler.resolve(clonedRequest);
    } else {
      return handler.next(error);
    }
  }));

  return dio;
}
