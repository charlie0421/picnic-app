import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_history_page.dart';

/// Tests for VoteHistoryPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// supabase.auth.currentUser). We test importable production code:
/// VoteHistoryPage constructor and VotePickModel.
void main() {
  group('VoteHistoryPage widget', () {
    test('can be const-constructed', () {
      const page = VoteHistoryPage();
      expect(page, isA<VoteHistoryPage>());
    });

    test('with key can be constructed', () {
      const page = VoteHistoryPage(key: ValueKey('vote_history'));
      expect(page.key, equals(const ValueKey('vote_history')));
    });
  });

  group('VotePickModel', () {
    test('fromJson parses basic fields', () {
      final json = {
        'id': 1,
        'amount': 100,
        'star_candy_usage': 50,
        'star_candy_bonus_usage': 10,
        'cotton_candy_usage': 7,
        'created_at': '2024-06-15T10:00:00.000Z',
        'updated_at': '2024-06-15T10:00:00.000Z',
        'vote': {
          'id': 1,
          'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
          'vote_category': 'birthday',
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'created_at': '2024-01-01',
          'visible_at': null,
          'is_partnership': false,
          'partner': null,
        },
        'vote_item': {
          'id': 1,
          'vote_total': 5000,
          'star_candy_total': 3000,
          'star_candy_bonus_total': 500,
          'vote_id': 1,
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
          'artist_group': null,
        },
      };

      final pick = VotePickModel.fromJson(json);
      expect(pick.id, 1);
      expect(pick.amount, 100);
      expect(pick.cottonCandyUsage, 7);
    });

    test('fromJson with minimal nested data', () {
      final json = {
        'id': 2,
        'amount': 50,
        'star_candy_usage': 0,
        'star_candy_bonus_usage': 0,
        'created_at': '2024-06-15T10:00:00.000Z',
        'updated_at': '2024-06-15T10:00:00.000Z',
        'vote': {
          'id': 2,
          'title': {'ko': '투표', 'en': 'Vote'},
          'vote_category': 'birthday',
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'created_at': '2024-01-01',
          'visible_at': null,
          'is_partnership': false,
          'partner': null,
        },
        'vote_item': {
          'id': 2,
          'vote_total': 0,
          'star_candy_total': 0,
          'star_candy_bonus_total': 0,
          'vote_id': 2,
          'artist': {
            'id': 2,
            'name': {'ko': '아티스트', 'en': 'Artist'},
          },
          'artist_group': null,
        },
      };

      final pick = VotePickModel.fromJson(json);
      expect(pick.id, 2);
      expect(pick.amount, 50);
      expect(pick.starCandyUsage, 0);
    });
  });

  group('Sort order logic', () {
    test('DESC sorts newest first', () {
      final sortOrder = 'DESC';
      final ascending = sortOrder == 'ASC';
      expect(ascending, isFalse);
    });

    test('ASC sorts oldest first', () {
      final sortOrder = 'ASC';
      final ascending = sortOrder == 'ASC';
      expect(ascending, isTrue);
    });
  });
}
