import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'vote_list_provider.dart';

part '../../generated/providers/vote_detail_provider.g.dart';

@riverpod
class AsyncVoteDetail extends _$AsyncVoteDetail {
  @override
  Future<VoteModel?> build(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  Future<VoteModel?> fetch(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    final voteTable = votePortal == VotePortal.vote ? 'vote' : 'pic_vote';
    final voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';

    try {
      logger.d('[AsyncVoteDetail] 직접 HTTP 요청으로 투표 상세 조회: $voteId');

      // 직접 HTTP 요청으로 투표 상세 정보 가져오기
      final response = await _executeDirectHttpQuerySingle(
        tableName: voteTable,
        selectFields: [
          'id',
          'main_image',
          'title',
          'start_at',
          'stop_at',
          'visible_at',
          'vote_category'
        ],
        filters: {'id': 'eq.$voteId'},
      );

      if (response == null || response.isEmpty) {
        logger.w('[AsyncVoteDetail] Vote with id $voteId not found');
        throw Exception('Vote not found');
      }

      final now = DateTime.now().toUtc();

      // Add a new field to indicate if the current time is after end_at
      response['is_ended'] = now.isAfter(DateTime.parse(response['stop_at']));
      response['is_upcoming'] =
          now.isBefore(DateTime.parse(response['start_at']));

      logger.d('[AsyncVoteDetail] 투표 상세 조회 성공: $voteId');
      return VoteModel.fromJson(response);
    } catch (e, s) {
      logger.e('[AsyncVoteDetail] Failed to load vote detail: $e',
          stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
    }
    return null;
  }

  /// 단일 레코드를 위한 직접 HTTP 요청 메서드
  Future<Map<String, dynamic>?> _executeDirectHttpQuerySingle({
    required String tableName,
    required List<String> selectFields,
    Map<String, dynamic>? filters,
  }) async {
    try {
      logger.d('[AsyncVoteDetail] 단일 레코드 직접 HTTP 쿼리: $tableName');

      // Supabase URL과 API Key 가져오기
      final supabaseUrl = Environment.supabaseUrl;
      final supabaseKey = Environment.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        logger.e('[AsyncVoteDetail] Supabase 설정이 없습니다');
        return null;
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

      // 단일 결과를 위한 limit 추가
      queryParams['limit'] = '1';

      // URI 구성
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      logger.d(
          '[AsyncVoteDetail] 요청 URL: ${uri.toString().substring(0, uri.toString().length > 100 ? 100 : uri.toString().length)}...');

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
          logger.w('[AsyncVoteDetail] HTTP 요청 타임아웃');
          return http.Response('[]', 408);
        },
      );

      logger.d('[AsyncVoteDetail] HTTP 응답 상태: ${response.statusCode}');

      // 응답 상태 확인
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List && jsonData.isNotEmpty) {
            final result = jsonData.first as Map<String, dynamic>;
            logger.d('[AsyncVoteDetail] 단일 레코드 조회 성공');
            return result;
          } else if (jsonData is List && jsonData.isEmpty) {
            logger.w('[AsyncVoteDetail] 결과 없음');
            return null;
          } else {
            logger.w('[AsyncVoteDetail] 예상치 못한 응답 형식: ${jsonData.runtimeType}');
            return null;
          }
        } catch (jsonError) {
          logger.e('[AsyncVoteDetail] JSON 파싱 실패: $jsonError');
          return null;
        }
      } else if (response.statusCode == 404) {
        logger.w('[AsyncVoteDetail] 테이블을 찾을 수 없음: $tableName');
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        logger.w('[AsyncVoteDetail] 인증/권한 오류: ${response.statusCode}');
        return null;
      } else {
        logger.w(
            '[AsyncVoteDetail] HTTP 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('[AsyncVoteDetail] 단일 레코드 HTTP 요청 실패: $e');
      return null;
    }
  }
}

@riverpod
class AsyncVoteItemList extends _$AsyncVoteItemList {
  @override
  FutureOr<List<VoteItemModel?>> build(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  FutureOr<List<VoteItemModel?>> fetch(
      {required int voteId, VotePortal votePortal = VotePortal.vote}) async {
    final voteItemTable =
        votePortal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';
    try {
      logger.d('[AsyncVoteItemList] 직접 HTTP 요청으로 투표 아이템 조회: $voteId');

      // 직접 HTTP 요청으로 투표 아이템 리스트 가져오기
      final response = await _executeDirectHttpQueryList(
        tableName: voteItemTable,
        selectFields: ['id', 'vote_id', 'vote_total'],
        filters: {
          'vote_id': 'eq.$voteId',
          'deleted_at': 'is.null',
        },
        orderBy: 'vote_total',
        ascending: false,
      );

      // 응답이 비어있으면 빈 리스트 반환
      if (response == null || response.isEmpty) {
        logger.i('[AsyncVoteItemList] No vote items found for voteId: $voteId');
        state = AsyncValue.data([]);
        return [];
      }

      // 안전한 JSON 변환
      List<VoteItemModel> voteItemList = [];
      for (final item in response) {
        try {
          if (item != null) {
            voteItemList.add(VoteItemModel.fromJson(item));
          }
        } catch (jsonError) {
          logger.w('[AsyncVoteItemList] Failed to parse vote item: $item',
              error: jsonError);
          // 개별 아이템 파싱 실패는 무시하고 계속 진행
        }
      }

      logger.d('[AsyncVoteItemList] 투표 아이템 조회 성공: ${voteItemList.length}개');
      state = AsyncValue.data(voteItemList);
      return voteItemList;
    } catch (e, s) {
      logger.e('[AsyncVoteItemList] Error fetching vote items',
          error: e, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );

      // 오류 시 빈 리스트 반환
      state = AsyncValue.data([]);
      return [];
    }
  }

  setVoteItem({required int id, required int voteTotal}) async {
    try {
      if (state.value != null) {
        final updatedList = state.value!.map<VoteItemModel>((item) {
          if (item != null && item.id == id) {
            item = item.copyWith(voteTotal: voteTotal);
          }
          return item!;
        }).toList();

        state = AsyncValue.data(updatedList);

        //sort by total_vote
        state = AsyncValue.data(state.value!.toList()
          ..sort((a, b) => b!.voteTotal!.compareTo(a!.voteTotal!)));

        logger.i('Updated vote item in state: $id with voteTotal: $voteTotal');
      }
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 리스트를 위한 직접 HTTP 요청 메서드
  Future<List<Map<String, dynamic>>?> _executeDirectHttpQueryList({
    required String tableName,
    required List<String> selectFields,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      logger.d('[AsyncVoteItemList] 리스트 직접 HTTP 쿼리: $tableName');

      // Supabase URL과 API Key 가져오기
      final supabaseUrl = Environment.supabaseUrl;
      final supabaseKey = Environment.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        logger.e('[AsyncVoteItemList] Supabase 설정이 없습니다');
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

      // URI 구성
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      logger.d(
          '[AsyncVoteItemList] 요청 URL: ${uri.toString().substring(0, uri.toString().length > 100 ? 100 : uri.toString().length)}...');

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
          logger.w('[AsyncVoteItemList] HTTP 요청 타임아웃');
          return http.Response('[]', 408);
        },
      );

      logger.d('[AsyncVoteItemList] HTTP 응답 상태: ${response.statusCode}');

      // 응답 상태 확인
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List) {
            final result = jsonData.cast<Map<String, dynamic>>();
            logger.d('[AsyncVoteItemList] 리스트 조회 성공: ${result.length}개');
            return result;
          } else {
            logger
                .w('[AsyncVoteItemList] 예상치 못한 응답 형식: ${jsonData.runtimeType}');
            return [];
          }
        } catch (jsonError) {
          logger.e('[AsyncVoteItemList] JSON 파싱 실패: $jsonError');
          return [];
        }
      } else if (response.statusCode == 404) {
        logger.w('[AsyncVoteItemList] 테이블을 찾을 수 없음: $tableName');
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        logger.w('[AsyncVoteItemList] 인증/권한 오류: ${response.statusCode}');
        return [];
      } else {
        logger.w(
            '[AsyncVoteItemList] HTTP 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('[AsyncVoteItemList] 리스트 HTTP 요청 실패: $e');
      return [];
    }
  }
}

@riverpod
Future<List<VoteAchieve>?> fetchVoteAchieve(ref, {required int voteId}) async {
  try {
    logger.d('[fetchVoteAchieve] 직접 HTTP 요청으로 투표 성취 조회: $voteId');

    // Supabase URL과 API Key 가져오기
    final supabaseUrl = Environment.supabaseUrl;
    final supabaseKey = Environment.supabaseAnonKey;

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      logger.e('[fetchVoteAchieve] Supabase 설정이 없습니다');
      return [];
    }

    // REST API URL 구성
    final String baseUrl = '$supabaseUrl/rest/v1/vote_achieve';
    final Map<String, String> queryParams = {
      'select': 'id,vote_id,reward_id,order,amount',
      'vote_id': 'eq.$voteId',
      'order': 'order.asc',
    };

    // URI 구성
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    // HTTP 헤더 설정
    final headers = {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // HTTP GET 요청 실행
    final httpResponse = await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        logger.w('[fetchVoteAchieve] HTTP 요청 타임아웃');
        return http.Response('[]', 408);
      },
    );

    logger.d('[fetchVoteAchieve] HTTP 응답 상태: ${httpResponse.statusCode}');

    // 응답 처리
    List<Map<String, dynamic>> response = [];
    if (httpResponse.statusCode == 200) {
      try {
        final jsonData = json.decode(httpResponse.body);
        if (jsonData is List) {
          response = jsonData.cast<Map<String, dynamic>>();
        }
      } catch (jsonError) {
        logger.e('[fetchVoteAchieve] JSON 파싱 실패: $jsonError');
        return [];
      }
    } else {
      logger.w('[fetchVoteAchieve] HTTP 오류: ${httpResponse.statusCode}');
      return [];
    }

    // 응답이 비어있으면 빈 리스트 반환
    if (response.isEmpty) {
      logger.i(
          '[fetchVoteAchieve] No vote achievements found for voteId: $voteId');
      return [];
    }

    // 안전한 JSON 변환
    List<VoteAchieve> achieveList = [];
    for (final item in response) {
      try {
        if (item != null) {
          achieveList.add(VoteAchieve.fromJson(item));
        }
      } catch (jsonError) {
        logger.w('[fetchVoteAchieve] Failed to parse vote achieve item: $item',
            error: jsonError);
        // 개별 아이템 파싱 실패는 무시하고 계속 진행
      }
    }

    logger.d('[fetchVoteAchieve] 투표 성취 조회 성공: ${achieveList.length}개');
    return achieveList;
  } catch (e, s) {
    logger.e('[fetchVoteAchieve] Error fetching vote achievements',
        error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);
    return [];
  }
}
