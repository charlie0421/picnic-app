import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/banner_list_provider.g.dart';

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    try {
      logger.d('[AsyncBannerList] 직접 HTTP 요청으로 베너 조회: $location');

      final now = DateTime.now().toUtc();
      
      // 직접 HTTP 요청으로 베너 데이터 가져오기
      final response = await _executeDirectHttpQuery(
        tableName: 'banner',
        selectFields: ['id', 'title', 'thumbnail', 'image', 'duration', 'link'],
        location: location,
        currentTime: now,
      );

      if (response == null || response.isEmpty) {
        logger.i('[AsyncBannerList] No banners found for location: $location');
        return [];
      }

      // 안전한 JSON 변환
      List<BannerModel> bannerList = [];
      for (final item in response) {
        try {
          if (item != null) {
            bannerList.add(BannerModel.fromJson(item));
          }
        } catch (jsonError) {
          logger.w('[AsyncBannerList] Failed to parse banner item: $item', error: jsonError);
          // 개별 아이템 파싱 실패는 무시하고 계속 진행
        }
      }

      logger.d('[AsyncBannerList] 베너 조회 성공: ${bannerList.length}개');
      return bannerList;
    } catch (e, s) {
      logger.e('[AsyncBannerList] Error fetching banners', error: e, stackTrace: s);
      return []; // 오류 시 빈 리스트 반환
    }
  }

  /// 베너를 위한 직접 HTTP 요청 메서드
  Future<List<Map<String, dynamic>>?> _executeDirectHttpQuery({
    required String tableName,
    required List<String> selectFields,
    required String location,
    required DateTime currentTime,
  }) async {
    try {
      logger.d('[AsyncBannerList] 베너 직접 HTTP 쿼리: $tableName');

      // Supabase URL과 API Key 가져오기
      final supabaseUrl = Environment.supabaseUrl;
      final supabaseKey = Environment.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        logger.e('[AsyncBannerList] Supabase 설정이 없습니다');
        return [];
      }

      // REST API URL 구성
      final String baseUrl = '$supabaseUrl/rest/v1/$tableName';
      final Map<String, String> queryParams = {};

      // Select 필드 추가
      if (selectFields.isNotEmpty) {
        queryParams['select'] = selectFields.join(',');
      } else {
        queryParams['select'] = '*';
      }

      // 기본 location 필터
      queryParams['location'] = 'eq.$location';

      // 복잡한 시간 필터는 간단하게 처리 (현재 시간 기준으로 유효한 베너만)
      final nowIso = currentTime.toIso8601String();
      
      // 시작 시간이 현재보다 과거이고 종료 시간이 현재보다 미래인 것
      // 또는 시작/종료 시간이 null인 것
      queryParams['or'] = '(and(start_at.lte.$nowIso,or(end_at.gte.$nowIso,end_at.is.null)),and(start_at.is.null,end_at.is.null))';

      // 정렬 추가
      queryParams['order'] = 'order.asc,start_at.desc';

      // URI 구성
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      logger.d('[AsyncBannerList] 요청 URL: ${uri.toString().substring(0, uri.toString().length > 100 ? 100 : uri.toString().length)}...');

      // HTTP 헤더 설정
      final headers = {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // HTTP GET 요청 실행
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          logger.w('[AsyncBannerList] HTTP 요청 타임아웃');
          return http.Response('[]', 408);
        },
      );

      logger.d('[AsyncBannerList] HTTP 응답 상태: ${response.statusCode}');

      // 응답 상태 확인
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List) {
            final result = jsonData.cast<Map<String, dynamic>>();
            logger.d('[AsyncBannerList] 베너 조회 성공: ${result.length}개');
            return result;
          } else {
            logger.w('[AsyncBannerList] 예상치 못한 응답 형식: ${jsonData.runtimeType}');
            return [];
          }
        } catch (jsonError) {
          logger.e('[AsyncBannerList] JSON 파싱 실패: $jsonError');
          return [];
        }
      } else if (response.statusCode == 404) {
        logger.w('[AsyncBannerList] 테이블을 찾을 수 없음: $tableName');
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        logger.w('[AsyncBannerList] 인증/권한 오류: ${response.statusCode}');
        return [];
      } else {
        logger.w('[AsyncBannerList] HTTP 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('[AsyncBannerList] 베너 HTTP 요청 실패: $e');
      return [];
    }
  }
}
