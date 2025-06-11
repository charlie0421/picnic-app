import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/vote_list_provider.g.dart';

enum VoteStatus { all, active, end, upcoming, activeAndUpcoming }

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

      // area가 'all'이 아닌 경우에만 area 필터 적용
      if (area != 'all') {
        query = query.eq('area', area);
      }

      query = query.filter('deleted_at', 'is', null);

      // 카테고리 필터 적용 ('all'이 아닌 경우에만)
      if (category != 'all') {
        query = query.eq('vote_category', category);
      }

      if (status == VoteStatus.active) {
        query = query
            .lt('visible_at', 'now()')
            .lt('start_at', 'now()')
            .gt('stop_at', 'now()');
      } else if (status == VoteStatus.end) {
        query = query.lt('stop_at', 'now()');
      } else if (status == VoteStatus.upcoming) {
        query = query.lt('visible_at', 'now()').gt('start_at', 'now()');
      } else if (status == VoteStatus.activeAndUpcoming) {
        query = query.lt('visible_at', 'now()').gt('stop_at', 'now()');
        sort = 'stop_at';
        order = 'ASC';
      }

      // area가 'all'인 경우 kpop을 먼저 보여주기 위한 정렬 추가
      if (area == 'all') {
        response = await query
            .order('area', ascending: true) // kpop이 musical보다 먼저 오도록
            .order(sort, ascending: order == 'ASC')
            .range(offset, offset + limit - 1);
      } else {
        response = await query
            .order(sort, ascending: order == 'ASC')
            .range(offset, offset + limit - 1);
      }

      // 각 투표에 대해 상위 3개 vote_item만 유지하여 메모리 사용량 최적화
      final optimizedResponse = response.map((voteData) {
        if (voteData[voteItemTable] is List) {
          final voteItems = voteData[voteItemTable] as List;
          // vote_total 기준으로 정렬하고 상위 3개만 유지
          voteItems.sort(
              (a, b) => (b['vote_total'] ?? 0).compareTo(a['vote_total'] ?? 0));
          voteData[voteItemTable] = voteItems.take(3).toList();
        }
        return voteData;
      }).toList();

      final result =
          optimizedResponse.map((e) => VoteModel.fromJson(e)).toList();

      // 메모리 프로파일링 완료
      MemoryProfiler.instance.takeSnapshot(
        'vote_list_fetch_end_$page',
        level: MemoryProfiler.snapshotLevelLow,
      );

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
