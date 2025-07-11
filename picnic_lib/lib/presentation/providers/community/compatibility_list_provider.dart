import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/compatibility_list_provider.g.dart';

@riverpod
class CompatibilityList extends _$CompatibilityList {
  static const int _pageSize = 10;
  static const String _table = 'compatibility_results';
  int? _artistId;

  @override
  CompatibilityHistoryModel build({int? artistId}) {
    _artistId = artistId;
    return const CompatibilityHistoryModel(
      items: [],
      hasMore: true,
      isLoading: false,
    );
  }

  Future<void> loadInitial() async {
    if (state.isLoading) {
      logger.d('🔄 CompatibilityList: 이미 로딩 중입니다');
      return;
    }

    logger.d('🚀 CompatibilityList: 초기 로딩 시작');

    // 🔧 인증 상태 먼저 확인
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      logger.w('⚠️ CompatibilityList: 사용자가 인증되지 않았습니다');
      state = state.copyWith(
        items: [],
        hasMore: false,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      logger.d('👤 CompatibilityList: 사용자 ID: $userId, 아티스트 ID: $_artistId');

      final items = await _getHistory(page: 0);

      logger.d('✅ CompatibilityList: ${items.length}개 아이템 로드 완료');

      state = state.copyWith(
        items: items,
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e, s) {
      logger.e('❌ CompatibilityList 초기 로딩 실패:', error: e, stackTrace: s);

      // 🔧 상세한 에러 정보 로그
      if (e.toString().contains('JWT')) {
        logger.e('🔑 JWT 토큰 문제 감지');
      } else if (e.toString().contains('network')) {
        logger.e('🌐 네트워크 연결 문제 감지');
      } else if (e.toString().contains('permission')) {
        logger.e('🚫 권한 문제 감지');
      }

      state = state.copyWith(
        isLoading: false,
        // 🔧 에러가 발생해도 빈 상태로 설정 (crash 방지)
        items: [],
        hasMore: false,
      );

      // 🔧 에러를 다시 던지지 않음 (UI crash 방지)
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      logger.d(
          '🔄 CompatibilityList: 추가 로딩 조건 불충족 (loading: ${state.isLoading}, hasMore: ${state.hasMore})');
      return;
    }

    // 🔧 인증 상태 확인
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      logger.w('⚠️ CompatibilityList: 사용자가 인증되지 않아 추가 로딩 중단');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final page = (state.items.length / _pageSize).floor();
      logger.d('📄 CompatibilityList: 페이지 $page 로딩 중...');

      final items = await _getHistory(page: page);

      logger.d('✅ CompatibilityList: 추가 ${items.length}개 아이템 로드 완료');

      state = state.copyWith(
        items: [...state.items, ...items],
        hasMore: items.length >= _pageSize,
        isLoading: false,
      );
    } catch (e, s) {
      logger.e('❌ CompatibilityList 추가 로딩 실패:', error: e, stackTrace: s);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<CompatibilityModel>> _getHistory({required int page}) async {
    final userId = supabase.auth.currentUser?.id;

    // 🔧 더 명확한 에러 메시지
    if (userId == null) {
      logger.e('🔑 CompatibilityList: 사용자 인증 필요');
      throw Exception('사용자 인증이 필요합니다. 로그인 후 다시 시도해주세요.');
    }

    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    logger.d('🔍 CompatibilityList: 쿼리 실행 - 페이지: $page, 범위: $from-$to');

    try {
      var query = supabase.from(_table).select('''
            *,
            artist(*),
            i18n: compatibility_results_i18n (
              language,
              score,
              score_title,
              compatibility_summary,
              details,
              tips
            )
          ''').eq('user_id', userId);

      if (_artistId != null) {
        query = query.eq('artist_id', _artistId!);
        logger.d('🎯 CompatibilityList: 아티스트 필터 적용 - ID: $_artistId');
      }

      final response =
          await query.order('created_at', ascending: false).range(from, to);

      logger.d('📊 CompatibilityList: 쿼리 응답 - ${response.length}개 행');

      if (response.isEmpty) {
        logger.d('📭 CompatibilityList: 결과가 비어있습니다');
        return [];
      }

      final results = (response as List).map((data) {
        try {
          return CompatibilityModel.fromJson(data);
        } catch (e) {
          logger.e('❌ CompatibilityList: 데이터 파싱 실패', error: e);
          logger.d('🗂️ 문제가 된 데이터: $data');
          rethrow;
        }
      }).toList();

      logger.d('✅ CompatibilityList: ${results.length}개 모델 파싱 완료');
      return results;
    } catch (e, s) {
      logger.e('❌ CompatibilityList: 데이터베이스 쿼리 실패:', error: e, stackTrace: s);

      // 🔧 구체적인 에러 분석
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('permission denied')) {
        throw Exception('데이터 접근 권한이 없습니다. 관리자에게 문의하세요.');
      } else if (errorMsg.contains('connection')) {
        throw Exception('네트워크 연결 문제가 발생했습니다. 인터넷 연결을 확인해주세요.');
      } else if (errorMsg.contains('timeout')) {
        throw Exception('요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('데이터를 불러오는 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }
}
