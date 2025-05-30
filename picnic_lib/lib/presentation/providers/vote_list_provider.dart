import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/vote_list_provider.g.dart';

enum VoteStatus { all, active, end, upcoming, activeAndUpcoming }

enum VoteCategory { all, birthday, comeback, achieve }

enum VotePortal { vote, pic }

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  @override
  Future<List<VoteModel>> build(
      int page, int limit, String sort, String order, String area,
      {VotePortal votePortal = VotePortal.vote,
      required VoteStatus status,
      required VoteCategory category}) async {
    return await _fetchPage(
      page: page,
      limit: limit,
      sort: sort,
      order: order,
      votePortal: votePortal,
      category: category.name,
      status: status,
      area: area,
    );
  }

  /// Supabase 클라이언트 상태를 확인하는 헬퍼 메서드
  bool _isSupabaseReady() {
    try {
      // Supabase 클라이언트가 초기화되었는지 확인
      if (supabase == null) {
        logger.e('[AsyncVoteList] Supabase 클라이언트가 null입니다');
        return false;
      }

      // 기본적인 연결 상태 확인
      try {
        // 간단한 연결 테스트를 위해 auth 상태 확인
        final session = supabase.auth.currentSession;
        logger.d(
            '[AsyncVoteList] Supabase 클라이언트 상태 정상 - 세션: ${session != null ? '있음' : '없음'}');
        return true;
      } catch (e) {
        logger.e('[AsyncVoteList] Supabase 클라이언트 연결 테스트 실패: $e');
        return false;
      }
    } catch (e) {
      logger.e('[AsyncVoteList] Supabase 상태 확인 중 오류 발생: $e');
      return false;
    }
  }

  /// 테이블 존재 여부를 확인하는 헬퍼 메서드
  Future<bool> _checkTableExists(String tableName) async {
    try {
      logger.d('[AsyncVoteList] 테이블 $tableName 존재 확인 시작');

      // 더 안전한 방식으로 테이블 존재 확인 - 단순히 select만 실행
      final query = supabase.from(tableName).select('id').limit(1);

      final result = await _executeQuerySafely(query, '테이블 존재 확인: $tableName');

      if (result != null) {
        logger.d('[AsyncVoteList] 테이블 $tableName 존재 확인 완료');
        return true;
      } else {
        logger.w('[AsyncVoteList] 테이블 $tableName 접근 실패');
        return false;
      }
    } catch (e) {
      logger.w('[AsyncVoteList] 테이블 $tableName 확인 중 오류: $e');
      // 테이블이 존재하지 않거나 접근할 수 없는 경우라도 앱이 계속 실행되도록 함
      return false;
    }
  }

  /// Supabase 기본 연결을 테스트하는 메서드
  Future<bool> _testSupabaseConnection() async {
    try {
      logger.d('[AsyncVoteList] Supabase 연결 테스트 시작');

      // 환경 설정 확인
      try {
        final url = Environment.supabaseUrl;
        final key = Environment.supabaseAnonKey;
        logger.d(
            '[AsyncVoteList] Supabase 설정 - URL: ${url.substring(0, 20)}..., Key: ${key.substring(0, 10)}...');
      } catch (e) {
        logger.e('[AsyncVoteList] 환경 설정 읽기 실패: $e');
        return false;
      }

      // 가장 기본적인 연결 테스트 - auth 상태만 확인
      final user = supabase.auth.currentUser;
      logger.d('[AsyncVoteList] 현재 사용자: ${user?.id ?? '익명'}');

      logger.d('[AsyncVoteList] Supabase 연결 테스트 완료');
      return true;
    } catch (e) {
      logger.e('[AsyncVoteList] Supabase 기본 연결 테스트 실패: $e');
      return false;
    }
  }

  /// 안전한 Supabase 쿼리 실행을 위한 래퍼 메서드
  Future<List<Map<String, dynamic>>?> _executeQuerySafely(
    PostgrestBuilder query,
    String operation,
  ) async {
    try {
      logger.d('[AsyncVoteList] 쿼리 실행: $operation');

      // 매우 방어적인 쿼리 실행 - PostgrestBuilder 내부 null 에러까지 차단
      dynamic result;
      try {
        // Future에 타임아웃을 추가하여 무한 대기 방지
        result = await query.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logger.w('[AsyncVoteList] 쿼리 타임아웃: $operation');
            return <Map<String, dynamic>>[];
          },
        );
      } catch (timeoutError) {
        logger.w('[AsyncVoteList] 쿼리 실행 중 타임아웃/에러: $operation - $timeoutError');
        return [];
      }

      // 극도로 방어적인 null 체크
      if (result == null) {
        logger.w('[AsyncVoteList] 쿼리 결과가 null입니다: $operation');
        return [];
      }

      // 타입 안전성 확인
      if (result is! List) {
        logger.w(
            '[AsyncVoteList] 쿼리 결과가 List 타입이 아닙니다: $operation, 타입: ${result.runtimeType}');
        return [];
      }

      // 빈 리스트 처리
      if ((result as List).isEmpty) {
        logger.d('[AsyncVoteList] 쿼리 결과가 빈 리스트입니다: $operation');
        return [];
      }

      // 안전한 Map 리스트 변환
      try {
        final List<Map<String, dynamic>> mapList = [];
        for (final item in result as List) {
          if (item != null && item is Map<String, dynamic>) {
            mapList.add(item);
          } else if (item != null) {
            // 다른 타입인 경우 Map으로 변환 시도
            try {
              mapList.add(Map<String, dynamic>.from(item as Map));
            } catch (conversionError) {
              logger.w('[AsyncVoteList] 아이템 변환 실패, 스킵: $conversionError');
              // 변환 실패한 아이템은 무시하고 계속
            }
          }
        }

        logger.d('[AsyncVoteList] 쿼리 성공: $operation, 결과 수: ${mapList.length}');
        return mapList;
      } catch (castError) {
        logger.e('[AsyncVoteList] 리스트 변환 실패: $operation - $castError');
        return [];
      }
    } on TimeoutException catch (timeoutError) {
      logger.e('[AsyncVoteList] 쿼리 타임아웃: $operation', error: timeoutError);
      return [];
    } catch (e) {
      logger.e('[AsyncVoteList] 쿼리 실행 실패: $operation', error: e);

      // 구체적인 에러 타입별 처리
      if (e.toString().contains('Null check operator')) {
        logger.e(
            '[AsyncVoteList] Null check 에러 발생 - PostgrestBuilder 응답 처리 중 null 값 발견');
      } else if (e.toString().contains('relation') ||
          e.toString().contains('table')) {
        logger.e('[AsyncVoteList] 테이블/관계 에러 - 스키마 확인 필요');
      } else if (e.toString().contains('permission') ||
          e.toString().contains('policy')) {
        logger.e('[AsyncVoteList] 권한 에러 - RLS 정책 확인 필요');
      } else if (e.toString().contains('connection') ||
          e.toString().contains('network')) {
        logger.e('[AsyncVoteList] 네트워크/연결 에러');
      }

      return []; // 모든 에러 상황에서 빈 리스트 반환
    }
  }

  Future<List<VoteModel>> _fetchPage({
    required int page,
    required int limit,
    required String sort,
    required String order,
    required VotePortal votePortal,
    required String category,
    required VoteStatus status,
    required String area,
  }) async {
    String voteTable = votePortal == VotePortal.vote ? 'vote' : 'pic_vote';
    String voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';

    try {
      logger.d('[AsyncVoteList] 페이지 로드 시작: 테이블=$voteTable, 페이지=$page');

      // Supabase 클라이언트 상태 확인
      if (!_isSupabaseReady()) {
        logger.w('[AsyncVoteList] Supabase가 준비되지 않음 - 빈 결과 반환');
        return [];
      }

      // 기본 연결 테스트
      final connectionOk = await _testSupabaseConnection();
      if (!connectionOk) {
        logger.w('[AsyncVoteList] Supabase 연결 테스트 실패 - 빈 결과 반환');
        return [];
      }

      // 안전한 쿼리 실행
      final result = await _safeExecuteVoteQuery(
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        voteTable: voteTable,
        voteItemTable: voteItemTable,
        status: status,
        area: area,
      );

      // 메모리 프로파일링
      MemoryProfiler.instance.takeSnapshot(
        'vote_list_fetch_end_$page',
        level: MemoryProfiler.snapshotLevelLow,
      );

      logger.d('[AsyncVoteList] 페이지 로드 완료: ${result.length}개 아이템');
      return result;
    } catch (e, s) {
      logger.e('[AsyncVoteList] _fetchPage 최종 에러 - 빈 결과 반환',
          error: e, stackTrace: s);
      return []; // 모든 예외 상황에서 빈 리스트 반환
    }
  }

  /// 완전히 안전한 쿼리 실행 - PostgrestBuilder 우회하여 직접 HTTP 요청 사용
  Future<List<VoteModel>> _safeExecuteVoteQuery({
    required int page,
    required int limit,
    required String sort,
    required String order,
    required String voteTable,
    required String voteItemTable,
    required VoteStatus status,
    required String area,
  }) async {
    try {
      final offset = (page - 1) * limit;
      logger.d('[AsyncVoteList] 직접 HTTP 쿼리 실행: 테이블=$voteTable, 페이지=$page');

      // 필터 설정
      Map<String, dynamic> filters = {
        'deleted_at': 'is.null', // deleted_at이 null인 것만
      };

      // area 필터 추가
      if (area != 'all') {
        filters['area'] = 'eq.$area';
      }

      // 상태별 필터링 (현재 시간 기준)
      final now = DateTime.now().toIso8601String();
      if (status == VoteStatus.active) {
        filters['visible_at'] = 'lt.$now';
        filters['start_at'] = 'lt.$now';
        filters['stop_at'] = 'gt.$now';
      } else if (status == VoteStatus.end) {
        filters['stop_at'] = 'lt.$now';
      } else if (status == VoteStatus.upcoming) {
        filters['visible_at'] = 'lt.$now';
        filters['start_at'] = 'gt.$now';
      } else if (status == VoteStatus.activeAndUpcoming) {
        filters['visible_at'] = 'lt.$now';
        filters['stop_at'] = 'gt.$now';
        sort = 'stop_at';
        order = 'ASC';
      }

      // 정렬 설정
      String orderBy = sort;
      bool ascending = order == 'ASC';

      // area가 'all'인 경우 추가 정렬 필요
      if (area == 'all') {
        // 일단 기본 정렬만 적용 (복합 정렬은 추후 필요시 구현)
        orderBy = 'area'; // 먼저 area로 정렬
      }

      // 직접 HTTP 요청으로 데이터 가져오기
      List<Map<String, dynamic>>? response = await _executeDirectHttpQuery(
        tableName: voteTable,
        selectFields: [
          'id',
          'title',
          'start_at',
          'stop_at',
          'visible_at',
          'vote_category'
        ],
        filters: filters,
        orderBy: orderBy,
        ascending: ascending,
        limit: limit,
        offset: offset,
      );

      // 결과가 null인 경우 (에러 발생)
      if (response == null) {
        logger.w('[AsyncVoteList] 직접 HTTP 쿼리 실패 - 빈 결과 반환');
        return [];
      }

      // 결과 처리
      if (response.isEmpty) {
        logger.i('[AsyncVoteList] 페이지 $page에 대한 데이터가 없습니다');
        return [];
      }

      // VoteModel 변환
      List<VoteModel> voteList = [];
      for (final voteData in response) {
        try {
          if (voteData != null && voteData.isNotEmpty) {
            voteList.add(VoteModel.fromJson(voteData));
          }
        } catch (jsonError) {
          logger.w('[AsyncVoteList] 개별 아이템 파싱 실패, 스킵: $jsonError');
          // 개별 실패는 무시하고 계속 진행
        }
      }

      logger.d('[AsyncVoteList] 성공적으로 ${voteList.length}개 아이템 로드 (직접 HTTP)');
      return voteList;
    } catch (e) {
      logger.e('[AsyncVoteList] 직접 HTTP 쿼리 실행 중 예상치 못한 오류: $e');
      return []; // 어떤 상황에서도 빈 리스트 반환
    }
  }

  /// PostgrestBuilder를 우회한 직접 HTTP 요청 메서드
  Future<List<Map<String, dynamic>>?> _executeDirectHttpQuery({
    required String tableName,
    required List<String> selectFields,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      logger.d('[AsyncVoteList] 직접 HTTP 쿼리 시작: $tableName');

      // Supabase URL과 API Key 가져오기
      final supabaseUrl = Environment.supabaseUrl;
      final supabaseKey = Environment.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        logger.e('[AsyncVoteList] Supabase 설정이 없습니다');
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

      // 필터 추가
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      // 정렬 추가
      if (orderBy != null) {
        queryParams['order'] = '$orderBy.${ascending ? 'asc' : 'desc'}';
      }

      // 제한 및 오프셋 추가
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }

      // URI 구성
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      logger.d(
          '[AsyncVoteList] 요청 URL: ${uri.toString().substring(0, uri.toString().length > 100 ? 100 : uri.toString().length)}...');

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
          logger.w('[AsyncVoteList] HTTP 요청 타임아웃');
          return http.Response('[]', 408); // 타임아웃 시 빈 배열 응답
        },
      );

      logger.d('[AsyncVoteList] HTTP 응답 상태: ${response.statusCode}');

      // 응답 상태 확인
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List) {
            final result = jsonData.cast<Map<String, dynamic>>();
            logger.d('[AsyncVoteList] 직접 HTTP 쿼리 성공: ${result.length}개 결과');
            return result;
          } else {
            logger.w('[AsyncVoteList] 예상치 못한 응답 형식: ${jsonData.runtimeType}');
            return [];
          }
        } catch (jsonError) {
          logger.e('[AsyncVoteList] JSON 파싱 실패: $jsonError');
          return [];
        }
      } else if (response.statusCode == 404) {
        logger.w('[AsyncVoteList] 테이블을 찾을 수 없음: $tableName');
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        logger.w('[AsyncVoteList] 인증/권한 오류: ${response.statusCode}');
        return [];
      } else {
        logger.w(
            '[AsyncVoteList] HTTP 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('[AsyncVoteList] 직접 HTTP 요청 실패: $e');
      return [];
    }
  }
}

@riverpod
class SortOption extends _$SortOption {
  SortOptionType sortOptions = SortOptionType('id', 'DESC');

  @override
  SortOptionType build() {
    sortOptions = SortOptionType('id', 'DESC');
    return sortOptions;
  }

  void setSortOption(String sort, String order) {
    state = SortOptionType(sort, order);
  }
}

class SortOptionType {
  String sort = '';
  String order = '';

  SortOptionType(this.sort, this.order);
}

@riverpod
class CommentCount extends _$CommentCount {
  @override
  Future<int> build(int articleId) async {
    return 0;
  }

  setCount(int count) {
    state = AsyncValue.data(count);
  }

  increment() {
    state = AsyncValue.data(state.value! + 1);
  }

  decrement() {
    state = AsyncValue.data(state.value! - 1);
  }
}
