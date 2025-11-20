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
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  }) async {
    // 🚨🚨🚨 빌드 메서드 호출 로깅
    logger.d('🚨🚨🚨 AsyncVoteList.build 메서드 시작');
    logger.d(
      '🔍 파라미터: status=$status, category=$category, area=$area, page=$page, limit=$limit',
    );

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
    // PIC 차트는 별도 테이블이 아닌 동일 테이블에서 카테고리로만 구분
    String voteTable = 'vote';
    String voteItemTable = 'vote_item';

    try {
      PostgrestList response;
      final offset = (page - 1) * limit;

      // 최적화: 목록에서는 필요한 필드만 선택하고, vote_item 정보는 이후 상태에 따라 가공
      var query = supabase.from(voteTable).select('''
            id,
            title,
            main_image,
            wait_image,
            result_image,
            vote_content,
            created_at,
            start_at,
            stop_at,
            visible_at,
            vote_category,
            is_partnership,
            partner,
            reward(*),
            $voteItemTable!inner(
              id,
              vote_id,
              vote_total,
              artist(id, name, image),
              artist_group(id, name, image)
            )
          ''');

      // area 필터 항상 적용 (Admin/Debug 포함)
      if (area != 'all') {
        query = query.eq('area', area);
      }

      query = query.filter('deleted_at', 'is', null);

      // 카테고리 직접 선택 시 우선 적용 (디버그 제외)
      if (category != 'all' && status != VoteStatus.debug) {
        query = query.eq('vote_category', category);
      }

      // 포털 분기 제거: 화면에서 후처리로 필터 (VoteList의 itemFilter)

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

      dynamic finalQuery = query;
      // area가 'all'이고, 기본 정렬(id)일 때만 kpop 우선 정렬 적용
      if (area == 'all' && finalSort == 'id') {
        finalQuery = finalQuery.order('area', ascending: true);
      }

      response = await finalQuery
          .order(finalSort, ascending: finalOrder == 'ASC')
          .range(offset, offset + limit - 1);

      final now = DateTime.now().toUtc();
      final processedResponse = response.map((voteData) {
        final map = Map<String, dynamic>.from(voteData);

        final startAtString = map['start_at'] as String?;
        final stopAtString = map['stop_at'] as String?;
        final startAt =
            startAtString != null ? DateTime.parse(startAtString).toUtc() : null;
        final stopAt =
            stopAtString != null ? DateTime.parse(stopAtString).toUtc() : null;

        final isUpcoming =
            startAt != null ? now.isBefore(startAt) : false;
        final isEnded = stopAt != null ? now.isAfter(stopAt) : false;

        map['is_upcoming'] = isUpcoming;
        map['is_ended'] = isEnded;

        if (status == VoteStatus.debug) {
          map[voteItemTable] = <Map<String, dynamic>>[];
        } else if (map[voteItemTable] is List) {
          final voteItems = (map[voteItemTable] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['deleted_at'] == null)
              .toList();

          voteItems.sort(
            (a, b) => (b['vote_total'] ?? 0).compareTo(a['vote_total'] ?? 0),
          );

          map[voteItemTable] =
              isUpcoming ? voteItems : voteItems.take(3).toList();
        } else {
          map[voteItemTable] = <Map<String, dynamic>>[];
        }

        map.putIfAbsent('reward', () => <dynamic>[]);
        map.putIfAbsent('vote_content', () => null);
        map.putIfAbsent('main_image', () => null);
        map.putIfAbsent('wait_image', () => null);
        map.putIfAbsent('result_image', () => null);
        map.putIfAbsent('is_partnership', () => null);
        map.putIfAbsent('partner', () => null);

        return map;
      }).toList();

      final result =
          processedResponse.map((e) => VoteModel.fromJson(e)).toList();

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
