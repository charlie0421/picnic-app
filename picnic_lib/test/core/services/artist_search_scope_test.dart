import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';

/// 뮤지컬 배우(is_musical=true) 노출 회귀 가드.
///
/// 마이아티스트/후보요청 검색에서 뮤지컬 배우가 사라졌던 버그는
/// 검색 쿼리가 `is_kpop=true` 만 필터하던 것이 원인이었다. 이 테스트는
/// area→검색범위, 검색범위→PostgREST 필터 매핑이 깨지지 않도록 고정한다.
void main() {
  group('artistSearchScopeForVoteArea', () {
    test('musical 투표는 뮤지컬 배우만(musicalOnly) 검색', () {
      expect(
        artistSearchScopeForVoteArea('musical'),
        ArtistSearchScope.musicalOnly,
      );
    });

    test('kpop 투표는 K-pop만(kpopOnly) 검색', () {
      expect(
        artistSearchScopeForVoteArea('kpop'),
        ArtistSearchScope.kpopOnly,
      );
    });

    test('area 가 null/미상이면 기존 동작(kpopOnly) 유지', () {
      expect(artistSearchScopeForVoteArea(null), ArtistSearchScope.kpopOnly);
      expect(artistSearchScopeForVoteArea(''), ArtistSearchScope.kpopOnly);
      expect(artistSearchScopeForVoteArea('etc'), ArtistSearchScope.kpopOnly);
    });
  });

  group('artistScopeOrFilter (PostgREST or= 필터)', () {
    test('kpopOnly → is_kpop 만', () {
      expect(
        artistScopeOrFilter(ArtistSearchScope.kpopOnly),
        'is_kpop.eq.true',
      );
    });

    test('musicalOnly → is_musical 만 (뮤지컬 배우 노출)', () {
      expect(
        artistScopeOrFilter(ArtistSearchScope.musicalOnly),
        'is_musical.eq.true',
      );
    });

    test('kpopAndMusical → is_kpop OR is_musical (마이아티스트)', () {
      expect(
        artistScopeOrFilter(ArtistSearchScope.kpopAndMusical),
        'is_kpop.eq.true,is_musical.eq.true',
      );
    });
  });

  group('VoteModel.area 파싱', () {
    Map<String, dynamic> baseVoteJson(String? area) => {
          'id': 1,
          'title': {'ko': '테스트', 'en': 'test'},
          'vote_category': null,
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': null,
          'created_at': null,
          'visible_at': null,
          'stop_at': null,
          'start_at': null,
          'is_ended': null,
          'is_upcoming': null,
          'is_partnership': null,
          'partner': null,
          'area': ?area,
          'reward': null,
        };

    test('area=musical 가 모델로 파싱됨', () {
      expect(VoteModel.fromJson(baseVoteJson('musical')).area, 'musical');
    });

    test('area 누락 시 null (하위 호환)', () {
      expect(VoteModel.fromJson(baseVoteJson(null)).area, isNull);
    });
  });
}
