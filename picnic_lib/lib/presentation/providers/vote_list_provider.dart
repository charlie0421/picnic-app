import 'package:picnic_lib/core/utils/logger.dart';

import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/vote_list_provider.g.dart';

enum VoteStatus { all, active, end, upcoming, activeAndUpcoming, debug }

enum VoteCategory { all, birthday, comeback, achieve, birth, debut, image }

enum VotePortal { vote, pic }

@riverpod
class AsyncVoteList extends _$AsyncVoteList {
  @override
  Future<List<VoteModel>> build(
      int page, int limit, String sort, String order, String area,
      {VotePortal votePortal = VotePortal.vote,
      required VoteStatus status,
      required VoteCategory category}) async {
    // 🚨🚨🚨 빌드 메서드 호출 로깅
    logger.d('🚨🚨🚨 AsyncVoteList.build 메서드 시작');
    logger.d(
        '🔍 파라미터: status=$status, category=$category, area=$area, page=$page, limit=$limit');

    if (status == VoteStatus.debug) {
      logger.d('🚨🚨🚨🚨🚨 디버그 모드로 build 메서드 진입 확인됨!');
    }

    // 정렬 키가 타임스탬프를 포함하는 경우 실제 정렬은 id로 처리
    final actualSort = sort.startsWith('id_') ? 'id' : sort;

    return await _fetchPage(
      page: page,
      limit: limit,
      sort: actualSort,
      order: order,
      votePortal: votePortal,
      category: category.name,
      status: status,
      area: area,
    );
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
      PostgrestList response;
      final offset = (page - 1) * limit;

      // 최적화: 목록에서는 상위 3개 vote_item만 가져오고, 필요한 필드만 선택
      var query = supabase.from(voteTable).select('''
            id,
            title,
            start_at,
            stop_at,
            visible_at,
            vote_category,
            $voteItemTable!inner(
              id,
              vote_id,
              vote_total,
              artist(id, name, image),
              artist_group(id, name, image)
            )
          ''');

      // 디버그 모드가 아닌 경우에만 area 필터 적용
      if (area != 'all' && status != VoteStatus.debug) {
        query = query.eq('area', area);
      }

      query = query.filter('deleted_at', 'is', null);

      // 디버그 모드가 아닌 경우에만 카테고리 필터 적용
      if (category != 'all' && status != VoteStatus.debug) {
        query = query.eq('vote_category', category);
      }

      String finalSort = sort;
      String finalOrder = order;

      if (status == VoteStatus.active) {
        query = query
            .lt('visible_at', 'now()')
            .lt('start_at', 'now()')
            .gt('stop_at', 'now()');
        finalSort = 'stop_at';
        finalOrder = 'ASC';
      } else if (status == VoteStatus.end) {
        query = query.lt('stop_at', 'now()');
        finalSort = 'stop_at';
        finalOrder = 'DESC';
      } else if (status == VoteStatus.upcoming) {
        query = query.lt('visible_at', 'now()').gt('start_at', 'now()');
        finalSort = 'start_at';
        finalOrder = 'ASC';
      } else if (status == VoteStatus.activeAndUpcoming) {
        query = query.lt('visible_at', 'now()').gt('stop_at', 'now()');
        finalSort = 'stop_at';
        finalOrder = 'ASC';
      } else if (status == VoteStatus.debug) {
        logger.d('🚨🚨🚨 디버그 모드 활성화됨! 모든 필터 제거');
        finalSort = 'id';
        finalOrder = 'DESC';
        logger.d('🚨🚨🚨 디버그 모드: 모든 날짜 조건 제거, id DESC 정렬');
      }

      var finalQuery = query;
      // area가 'all'이고, 기본 정렬(id)일 때만 kpop 우선 정렬 적용
      if (area == 'all' && finalSort == 'id') {
        finalQuery = finalQuery.order('area', ascending: true);
      }

      response = await finalQuery
          .order(finalSort, ascending: finalOrder == 'ASC')
          .range(offset, offset + limit - 1);

      // 디버그 모드가 아닌 경우에만 vote_item 최적화 수행
      List<dynamic> finalResponse;
      if (status == VoteStatus.debug) {
        // 디버그 모드: vote_item이 없으므로 빈 배열 추가하여 JSON 파싱 오류 방지
        logger.d('🚨🚨🚨 디버그 모드: vote_item 필드를 빈 배열로 추가');
        finalResponse = response.map((voteData) {
          voteData[voteItemTable] = []; // 빈 vote_item 배열 추가
          return voteData;
        }).toList();
      } else {
        // 일반 모드: 각 투표에 대해 상위 3개 vote_item만 유지
        finalResponse = response.map((voteData) {
          if (voteData[voteItemTable] is List) {
            final voteItems = voteData[voteItemTable] as List;
            // vote_total 기준으로 정렬하고 상위 3개만 유지
            voteItems.sort((a, b) =>
                (b['vote_total'] ?? 0).compareTo(a['vote_total'] ?? 0));
            voteData[voteItemTable] = voteItems.take(3).toList();
          }
          return voteData;
        }).toList();
      }

      final result = finalResponse.map((e) => VoteModel.fromJson(e)).toList();

      // 디버그 상태에서 결과 상세 로그 출력
      if (status == VoteStatus.debug) {
        logger.d('🚨🚨🚨 디버그 쿼리 결과 분석:');
        logger.d('📊 총 ${result.length}개 투표 반환됨 (페이지 $page, 제한 $limit)');

        if (result.isNotEmpty) {
          logger.d('📋 투표 목록:');
          for (int i = 0; i < result.length && i < 10; i++) {
            final vote = result[i];
            final title =
                vote.title['ko'] ?? vote.title['en'] ?? 'Unknown Title';
            logger.d('  ${i + 1}. [${vote.id}] $title');
            logger.d('     시작: ${vote.startAt}');
            logger.d('     종료: ${vote.stopAt}');
            logger.d('     공개: ${vote.visibleAt}');
            logger.d('     ---');
          }

          if (result.length > 10) {
            logger.d('... 외 ${result.length - 10}개 더');
          }
        } else {
          logger.d('❌ 반환된 투표 없음');
        }
      }

      return result;
    } catch (e, s) {
      logger.e('투표 목록 로딩 오류', error: e, stackTrace: s);
      rethrow;
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

  void setCount(int count) {
    state = AsyncValue.data(count);
  }

  void increment() {
    state = AsyncValue.data(state.value! + 1);
  }

  void decrement() {
    state = AsyncValue.data(state.value! - 1);
  }
}
