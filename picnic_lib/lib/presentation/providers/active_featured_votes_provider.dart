import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/active_featured_votes_provider.g.dart';

/// 홈 "현재 진행중인 투표" 캐러셀용 엔트리.
/// vote(1위 항목 포함) + 해당 투표의 전체 득표 합계(퍼센트 계산용).
class FeaturedVoteEntry {
  final VoteModel vote;
  final int totalVotes;

  const FeaturedVoteEntry({required this.vote, required this.totalVotes});

  /// 1위 항목의 득표 점유율(0.0 ~ 1.0). 총합이 0이면 0.
  double get topPercent {
    final items = vote.voteItem;
    if (items == null || items.isEmpty || totalVotes <= 0) return 0;
    final top = items.first.voteTotal ?? 0;
    return top / totalVotes;
  }
}

/// 진행중(active)인 투표들을 stop_at 임박 순으로 최대 [_limit]개 반환.
/// 각 vote 는 표시용으로 1위 항목만 join 하고, 퍼센트 표시를 위해
/// vote_item.vote_total 만 가볍게 집계해 총합을 구한다.
@riverpod
class AsyncActiveFeaturedVotes extends _$AsyncActiveFeaturedVotes {
  static const int _limit = 10;

  @override
  Future<List<FeaturedVoteEntry>> build() async {
    try {
      final response = await supabase
          .from('vote')
          .select('''
            id, title, main_image, wait_image, result_image, vote_content,
            created_at, start_at, stop_at, visible_at, vote_category,
            is_partnership, partner, area, reward(*),
            vote_item!inner(
              id, vote_id, vote_total,
              artist(id, name, image),
              artist_group(id, name, image)
            )
          ''')
          .lt('visible_at', 'now()')
          .lt('start_at', 'now()')
          .gt('stop_at', 'now()')
          .filter('deleted_at', 'is', null)
          .order('vote_total', referencedTable: 'vote_item', ascending: false)
          .limit(1, referencedTable: 'vote_item')
          .order('stop_at', ascending: true)
          .limit(_limit);

      if (response.isEmpty) return <FeaturedVoteEntry>[];

      final votes = response.map((row) {
        final map = Map<String, dynamic>.from(row);
        map['is_upcoming'] = false;
        map['is_ended'] = false;
        if (map['vote_item'] is List) {
          map['vote_item'] = (map['vote_item'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => e['deleted_at'] == null)
              .take(1)
              .toList();
        } else {
          map['vote_item'] = <Map<String, dynamic>>[];
        }
        map.putIfAbsent('reward', () => <dynamic>[]);
        map.putIfAbsent('vote_content', () => null);
        map.putIfAbsent('main_image', () => null);
        map.putIfAbsent('wait_image', () => null);
        map.putIfAbsent('result_image', () => null);
        map.putIfAbsent('is_partnership', () => null);
        map.putIfAbsent('partner', () => null);
        return VoteModel.fromJson(map);
      }).toList();

      // 총합: vote_item.vote_total 만 선택(가벼움) 후 vote_id 별 합산.
      final voteIds = votes.map((v) => v.id).toList();
      final totals = <int, int>{};
      if (voteIds.isNotEmpty) {
        final totalRows = await supabase
            .from('vote_item')
            .select('vote_id, vote_total')
            .inFilter('vote_id', voteIds)
            .filter('deleted_at', 'is', null);
        for (final r in totalRows) {
          final vid = r['vote_id'] as int?;
          final vt = (r['vote_total'] as int?) ?? 0;
          if (vid != null) {
            totals[vid] = (totals[vid] ?? 0) + vt;
          }
        }
      }

      return votes
          .map((v) => FeaturedVoteEntry(vote: v, totalVotes: totals[v.id] ?? 0))
          .toList();
    } catch (e, s) {
      logger.e('active featured votes load error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
