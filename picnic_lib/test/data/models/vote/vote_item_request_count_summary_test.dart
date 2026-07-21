import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_count_summary.dart';

void main() {
  test('상태별 집계 행을 아티스트별 합계로 합친다', () {
    final summary = VoteItemRequestCountSummary.fromRows([
      {
        'artist_id': 10,
        'artist_name': '가수 A',
        'request_status': 'pending',
        'request_count': 2,
      },
      {
        'artist_id': 10,
        'artist_name': '가수 A',
        'request_status': 'approved',
        'request_count': 3,
      },
      {
        'artist_id': 20,
        'artist_name': '가수 B',
        'request_status': 'pending',
        'request_count': 1,
      },
    ]);

    expect(summary.totalCount, 6);
    expect(summary.countsByArtistId, {10: 5, 20: 1});
    expect(summary.countsByArtistName, {'가수 A': 5, '가수 B': 1});
    expect(summary.statusCountsByArtistId[10], {'pending': 2, 'approved': 3});
  });

  test('잘못된 행과 음수 개수는 집계에서 제외한다', () {
    final summary = VoteItemRequestCountSummary.fromRows([
      {
        'artist_id': null,
        'artist_name': '누락',
        'request_status': 'pending',
        'request_count': 2,
      },
      {
        'artist_id': 10,
        'artist_name': '가수 A',
        'request_status': 'pending',
        'request_count': -1,
      },
      {
        'artist_id': 10,
        'artist_name': '가수 A',
        'request_status': 'pending',
        'request_count': 2,
      },
    ]);

    expect(summary.totalCount, 2);
    expect(summary.countsByArtistId, {10: 2});
  });
}
