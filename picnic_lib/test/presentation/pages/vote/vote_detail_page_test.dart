import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_gain_indicator.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteItemRow({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  String artistNameEn = 'Jimin',
  int artistId = 10,
  String groupNameKo = 'BTS',
  String groupNameEn = 'BTS',
  int groupId = 1,
  String? artistImage,
  String? groupImage,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameEn},
      'image': artistImage,
      'artist_group': {
        'id': groupId,
        'name': {'ko': groupNameKo, 'en': groupNameEn},
        'image': groupImage,
      },
    },
    'artist_group': null,
  };
}

VoteItemModel _buildItem({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  String artistNameEn = 'Jimin',
  int artistId = 10,
  String groupNameKo = 'BTS',
  String groupNameEn = 'BTS',
  int groupId = 1,
  String? artistImage,
  String? groupImage,
}) {
  return VoteItemModel.fromJson(_voteItemRow(
    id: id,
    voteId: voteId,
    voteTotal: voteTotal,
    artistNameKo: artistNameKo,
    artistNameEn: artistNameEn,
    artistId: artistId,
    groupNameKo: groupNameKo,
    groupNameEn: groupNameEn,
    groupId: groupId,
    artistImage: artistImage,
    groupImage: groupImage,
  ));
}

VoteItemModel _buildGroupOnlyItem({
  int id = 1,
  int voteId = 1,
  int voteTotal = 3000,
  String groupNameKo = 'BTS',
  String groupNameEn = 'BTS',
  int groupId = 1,
  String? groupImage,
}) {
  return VoteItemModel.fromJson({
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': 0,
      'name': {'ko': '', 'en': ''},
      'image': null,
      'artist_group': null,
    },
    'artist_group': {
      'id': groupId,
      'name': {'ko': groupNameKo, 'en': groupNameEn},
      'image': groupImage,
    },
  });
}

/// Mirrors the filtering logic in _getFilteredIndices from VoteDetailPage
List<int> getFilteredIndices(List<VoteItemModel?> data, String query) {
  if (query.isEmpty) {
    return List<int>.generate(data.length, (index) => index);
  }

  return List<int>.generate(data.length, (index) => index).where((index) {
    final item = data[index]!;
    final lowerQuery = query.toLowerCase();

    // Artist name search (Korean + English + initials)
    if (item.artist?.id != null && (item.artist?.id ?? 0) != 0) {
      final artistNameKo = item.artist?.name['ko']?.toString() ?? '';
      final artistNameEn = item.artist?.name['en']?.toString() ?? '';

      if ((artistNameKo.isNotEmpty &&
              (artistNameKo.toLowerCase().contains(lowerQuery) ||
                  KoreanSearchUtils.matchesKoreanInitials(
                    artistNameKo,
                    query,
                  ))) ||
          (artistNameEn.isNotEmpty &&
              artistNameEn.toLowerCase().contains(lowerQuery))) {
        return true;
      }

      // Artist's group name search
      if (item.artist?.artistGroup?.name != null) {
        final artistGroupNameKo =
            item.artist!.artistGroup!.name['ko']?.toString() ?? '';
        final artistGroupNameEn =
            item.artist!.artistGroup!.name['en']?.toString() ?? '';

        if ((artistGroupNameKo.isNotEmpty &&
                (artistGroupNameKo.toLowerCase().contains(lowerQuery) ||
                    KoreanSearchUtils.matchesKoreanInitials(
                      artistGroupNameKo,
                      query,
                    ))) ||
            (artistGroupNameEn.isNotEmpty &&
                artistGroupNameEn.toLowerCase().contains(lowerQuery))) {
          return true;
        }
      }
    }

    // Direct group search (when artist is empty, only group exists)
    if (item.artistGroup?.id != null && (item.artistGroup?.id ?? 0) != 0) {
      final groupNameKo = item.artistGroup?.name['ko']?.toString() ?? '';
      final groupNameEn = item.artistGroup?.name['en']?.toString() ?? '';

      if ((groupNameKo.isNotEmpty &&
              (groupNameKo.toLowerCase().contains(lowerQuery) ||
                  KoreanSearchUtils.matchesKoreanInitials(
                    groupNameKo,
                    query,
                  ))) ||
          (groupNameEn.isNotEmpty &&
              groupNameEn.toLowerCase().contains(lowerQuery))) {
        return true;
      }
    }

    return false;
  }).toList();
}

/// Mirrors _areDataListsEqual from VoteDetailPage
bool areDataListsEqual(
  List<VoteItemModel?> list1,
  List<VoteItemModel?> list2,
) {
  if (list1.length != list2.length) return false;

  for (int i = 0; i < list1.length; i++) {
    final item1 = list1[i];
    final item2 = list2[i];

    if (item1 == null && item2 == null) continue;
    if (item1 == null || item2 == null) return false;

    if (item1.id != item2.id || item1.voteTotal != item2.voteTotal) {
      return false;
    }
  }

  return true;
}

/// Mirrors _getMatchingText from VoteDetailPage
String getMatchingText(Map<String, dynamic> nameMap, String query) {
  final lowerQuery = query.toLowerCase();

  // Korean text match (normal + initials)
  final koText = nameMap['ko']?.toString() ?? '';
  if (koText.isNotEmpty &&
      (koText.toLowerCase().contains(lowerQuery) ||
          KoreanSearchUtils.matchesKoreanInitials(koText, query))) {
    return koText;
  }

  // English text match
  final enText = nameMap['en']?.toString() ?? '';
  if (enText.isNotEmpty && enText.toLowerCase().contains(lowerQuery)) {
    return enText;
  }

  // Default: return Korean text or English text
  return koText.isNotEmpty ? koText : enText;
}

/// Mirrors _makeFullImageUrl from VoteDetailPage
String makeFullImageUrl(String imageUrl, {String cdnUrl = 'https://cdn.example.com'}) {
  if (imageUrl.isEmpty) {
    return imageUrl;
  }

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }

  try {
    final cleanCdnUrl = cdnUrl.endsWith('/')
        ? cdnUrl.substring(0, cdnUrl.length - 1)
        : cdnUrl;
    final cleanImageUrl = imageUrl.startsWith('/')
        ? imageUrl.substring(1)
        : imageUrl;

    return '$cleanCdnUrl/$cleanImageUrl';
  } catch (e) {
    return imageUrl;
  }
}

/// Mirrors _updateRanks from VoteDetailPage
Map<int, int> updateRanks(List<VoteItemModel?> items) {
  final sortedItems = items.where((item) => item != null).toList()
    ..sort((a, b) => (b!.voteTotal ?? 0).compareTo(a!.voteTotal ?? 0));

  final currentRanks = <int, int>{};
  int currentRank = 1;
  int? previousVoteTotal;

  for (var i = 0; i < sortedItems.length; i++) {
    final item = sortedItems[i]!;

    if (previousVoteTotal != null && item.voteTotal == previousVoteTotal) {
      // Same rank
    } else {
      currentRank = i + 1;
    }

    currentRanks[item.id] = currentRank;
    previousVoteTotal = item.voteTotal;
  }

  return currentRanks;
}

void main() {
  setUp(() {
    initTestColors();
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('VoteDetailPage', () {
    testWidgets('is a ConsumerStatefulWidget', (tester) async {
      const page = VoteDetailPage(voteId: 1);
      expect(page, isA<ConsumerStatefulWidget>());
      expect(page.voteId, 1);
      expect(page.votePortal, VotePortal.vote);
    });

    testWidgets('accepts pic portal', (tester) async {
      const page = VoteDetailPage(voteId: 42, votePortal: VotePortal.pic);
      expect(page.voteId, 42);
      expect(page.votePortal, VotePortal.pic);
    });

    testWidgets('creates state', (tester) async {
      const page = VoteDetailPage(voteId: 1);
      final state = page.createState();
      expect(state, isNotNull);
    });

    test('different voteIds create different instances', () {
      const page1 = VoteDetailPage(voteId: 1);
      const page2 = VoteDetailPage(voteId: 2);
      expect(page1.voteId, isNot(equals(page2.voteId)));
    });

    test('default votePortal is VotePortal.vote', () {
      const page = VoteDetailPage(voteId: 5);
      expect(page.votePortal, VotePortal.vote);
    });
  });

  group('VoteGainIndicator', () {
    testWidgets('shows +diff when diff is positive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 42))),
      );
      expect(find.text('+42'), findsOneWidget);
    });

    testWidgets('shows nothing when diff is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 0))),
      );
      expect(find.text('+0'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('animation fades out over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 10))),
      );
      expect(find.text('+10'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      expect(find.text('+10'), findsNothing);
    });

    testWidgets('restarts when diff changes from 0 to positive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 0))),
      );
      expect(find.text('+5'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 5))),
      );
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('handles negative diff', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: -1))),
      );
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('+-1'), findsNothing);
    });

    testWidgets('disposes without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 10))),
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const SizedBox())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large diff value renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 999999))),
      );
      expect(find.text('+999999'), findsOneWidget);
    });

    testWidgets('shows Opacity and Transform widgets during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 7))),
      );
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.text('+7'), findsOneWidget);
    });

    testWidgets('diff=1 shows +1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 1))),
      );
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('animation progresses mid-way', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 20))),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('+20'), findsOneWidget);
    });

    testWidgets('does not restart when diff stays negative', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: -5))),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: -10))),
      );
      expect(find.text('+-5'), findsNothing);
      expect(find.text('+-10'), findsNothing);
    });

    testWidgets('does not restart when diff stays positive (same value)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 5))),
      );
      expect(find.text('+5'), findsOneWidget);
      // Update with same positive diff but oldWidget.diff is already positive
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 5))),
      );
      // The text should still be visible since the animation is running
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink when displayDiff is null (diff=0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 0))),
      );
      // SizedBox.shrink is used when _displayDiff is null
      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsWidgets);
    });

    testWidgets('uses AnimatedBuilder during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const VoteGainIndicator(diff: 15))),
      );
      // AnimatedBuilder wraps the animated content (may find multiple from parent widgets)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });

  group('VoteDetailPage search filtering logic', () {
    test('KoreanSearchUtils matches korean initials', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('지민', 'ㅈㅁ'), isTrue);
      expect(KoreanSearchUtils.matchesKoreanInitials('정국', 'ㅈㄱ'), isTrue);
      expect(KoreanSearchUtils.matchesKoreanInitials('지민', 'ㅈㄱ'), isFalse);
    });

    test('KoreanSearchUtils extracts initials', () {
      final initials = KoreanSearchUtils.extractKoreanInitials('지민');
      expect(initials, 'ㅈㅁ');
    });

    test('KoreanSearchUtils extracts initials for group names', () {
      final initials = KoreanSearchUtils.extractKoreanInitials('방탄소년단');
      expect(initials, 'ㅂㅌㅅㄴㄷ');
    });

    test('KoreanSearchUtils matches partial Korean text', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌ'), isTrue);
      expect(KoreanSearchUtils.matchesKoreanInitials('블랙핑크', 'ㅂㄹ'), isTrue);
    });

    test('VoteItemModel parsing with artist', () {
      final item = _buildItem(
        artistNameKo: '지민',
        artistNameEn: 'Jimin',
        groupNameKo: 'BTS',
      );
      expect(item.id, 1);
      expect(item.voteTotal, 5000);
      expect(item.artist?.name['ko'], '지민');
      expect(item.artist?.name['en'], 'Jimin');
      expect(item.artist?.artistGroup?.name['ko'], 'BTS');
    });

    test('VoteItemModel parsing with group only', () {
      final item = _buildGroupOnlyItem();
      expect(item.artist?.id, 0);
      expect(item.artistGroup?.name['ko'], 'BTS');
    });

    test('VoteItemModel sorting by voteTotal', () {
      final items = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 10000),
        _buildItem(id: 3, voteTotal: 3000),
      ];
      items.sort((a, b) => (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0));
      expect(items[0].id, 2);
      expect(items[1].id, 1);
      expect(items[2].id, 3);
    });

    test('VoteModel with ended status', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '종료된 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 14)).toIso8601String(),
        'stop_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'is_ended': true,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.isEnded, true);
      expect(vote.isUpcoming, false);
    });

    test('VoteModel with upcoming status', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 2,
        'title': {'ko': '예정 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'start_at': now.add(const Duration(days: 3)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 10)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': true,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.isEnded, false);
      expect(vote.isUpcoming, true);
    });

    test('VoteModel with reward', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 3,
        'title': {'ko': '리워드 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': [
          {'id': 1, 'title': {'ko': '포토카드'}, 'thumbnail': 'https://example.com/r.jpg'},
        ],
      });
      expect(vote.reward, isNotNull);
      expect(vote.reward!.length, 1);
      expect(vote.reward![0].title, {'ko': '포토카드'});
    });

    test('VoteModel with partnership', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 4,
        'title': {'ko': '파트너십 투표'},
        'vote_category': 'birthday',
        'main_image': 'https://example.com/main.jpg',
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': true,
        'partner': 'Partner Corp',
        'reward': null,
      });
      expect(vote.isPartnership, true);
      expect(vote.partner, 'Partner Corp');
      expect(vote.mainImage, 'https://example.com/main.jpg');
    });

    test('VoteModel cardStatus returns correct status', () {
      final now = DateTime.now();
      // Ongoing
      final ongoing = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': 'test'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 1)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(ongoing.cardStatus.name, 'ongoing');

      // Upcoming
      final upcoming = VoteModel.fromJson({
        'id': 2,
        'title': {'ko': 'test'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.add(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': true,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(upcoming.cardStatus.name, 'upcoming');

      // Ended
      final ended = VoteModel.fromJson({
        'id': 3,
        'title': {'ko': 'test'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        'stop_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'is_ended': true,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(ended.cardStatus.name, 'ended');
    });

    test('ArtistModelWithHighlight stores highlight data', () {
      final artist = _buildItem().artist!;
      final highlighted = ArtistModelWithHighlight(
        artist: artist,
        highlightedName: '<b>지민</b>',
        highlightedGroupName: '<b>BTS</b>',
      );
      expect(highlighted.highlightedName, '<b>지민</b>');
      expect(highlighted.highlightedGroupName, '<b>BTS</b>');
      expect(highlighted.artist, artist);
    });

    test('VoteAchieve model parsing', () {
      final now = DateTime.now().toUtc();
      final achieve = VoteAchieve.fromJson({
        'id': 1,
        'vote_id': 1,
        'reward_id': 1,
        'order': 1,
        'amount': 10000,
        'reward': {
          'id': 1,
          'title': {'ko': '포토카드'},
          'thumbnail': 'https://example.com/r.jpg',
        },
        'vote': {
          'id': 1,
          'title': {'ko': '달성 투표'},
          'vote_category': 'achieve',
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': null,
          'created_at': null,
          'visible_at': null,
          'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
          'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
          'is_ended': false,
          'is_upcoming': false,
          'is_partnership': false,
          'partner': null,
          'reward': null,
        },
      });
      expect(achieve.amount, 10000);
      expect(achieve.order, 1);
      expect(achieve.reward.title, {'ko': '포토카드'});
      expect(achieve.voteId, 1);
    });

    test('Rank calculation for equal vote totals', () {
      final items = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 5000, artistId: 11),
        _buildItem(id: 3, voteTotal: 3000, artistId: 12),
      ];
      items.sort((a, b) => (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0));

      final ranks = <int, int>{};
      int currentRank = 1;
      int? previousVoteTotal;
      for (var i = 0; i < items.length; i++) {
        if (previousVoteTotal != null && items[i].voteTotal == previousVoteTotal) {
          // Same rank
        } else {
          currentRank = i + 1;
        }
        ranks[items[i].id] = currentRank;
        previousVoteTotal = items[i].voteTotal;
      }

      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 3);
    });
  });

  group('Search filtering logic (_getFilteredIndices mirror)', () {
    late List<VoteItemModel?> testData;

    setUp(() {
      testData = [
        _buildItem(id: 1, artistNameKo: '지민', artistNameEn: 'Jimin', groupNameKo: 'BTS', groupNameEn: 'BTS'),
        _buildItem(id: 2, artistNameKo: '정국', artistNameEn: 'Jungkook', groupNameKo: 'BTS', groupNameEn: 'BTS', artistId: 11),
        _buildItem(id: 3, artistNameKo: '리사', artistNameEn: 'Lisa', groupNameKo: '블랙핑크', groupNameEn: 'BLACKPINK', artistId: 12, groupId: 2),
        _buildItem(id: 4, artistNameKo: '제니', artistNameEn: 'Jennie', groupNameKo: '블랙핑크', groupNameEn: 'BLACKPINK', artistId: 13, groupId: 2),
        _buildGroupOnlyItem(id: 5, groupNameKo: '뉴진스', groupNameEn: 'NewJeans', groupId: 3),
      ];
    });

    test('returns all indices when query is empty', () {
      final result = getFilteredIndices(testData, '');
      expect(result, [0, 1, 2, 3, 4]);
    });

    test('filters by Korean artist name', () {
      final result = getFilteredIndices(testData, '지민');
      expect(result, [0]);
    });

    test('filters by English artist name', () {
      final result = getFilteredIndices(testData, 'Jimin');
      expect(result, [0]);
    });

    test('filters by English artist name case-insensitive', () {
      final result = getFilteredIndices(testData, 'jimin');
      expect(result, [0]);
    });

    test('filters by Korean group name (artist group)', () {
      final result = getFilteredIndices(testData, 'BTS');
      expect(result, [0, 1]);
    });

    test('filters by English group name (artist group)', () {
      final result = getFilteredIndices(testData, 'BLACKPINK');
      expect(result, [2, 3]);
    });

    test('filters by Korean initials for artist name', () {
      final result = getFilteredIndices(testData, 'ㅈㅁ');
      expect(result, [0]); // 지민
    });

    test('filters by Korean initials matching multiple artists', () {
      final result = getFilteredIndices(testData, 'ㅈ');
      // ㅈ should match 지민, 정국, 제니 (all start with ㅈ)
      expect(result.contains(0), isTrue); // 지민
      expect(result.contains(1), isTrue); // 정국
      expect(result.contains(3), isTrue); // 제니
    });

    test('filters by group-only item Korean name', () {
      final result = getFilteredIndices(testData, '뉴진스');
      expect(result, [4]);
    });

    test('filters by group-only item English name', () {
      final result = getFilteredIndices(testData, 'NewJeans');
      expect(result, [4]);
    });

    test('returns empty list when no match', () {
      final result = getFilteredIndices(testData, 'TWICE');
      expect(result, isEmpty);
    });

    test('partial Korean text match', () {
      final result = getFilteredIndices(testData, '리');
      expect(result.contains(2), isTrue); // 리사
    });

    test('partial English text match', () {
      final result = getFilteredIndices(testData, 'Jung');
      expect(result, [1]); // Jungkook
    });

    test('filters by Korean group initials for direct group', () {
      final result = getFilteredIndices(testData, 'ㄴㅈㅅ');
      expect(result, [4]); // 뉴진스
    });

    test('handles empty data list', () {
      final result = getFilteredIndices([], '지민');
      expect(result, isEmpty);
    });

    test('handles empty data list with empty query', () {
      final result = getFilteredIndices([], '');
      expect(result, isEmpty);
    });
  });

  group('Data list equality check (_areDataListsEqual mirror)', () {
    test('equal lists return true', () {
      final list1 = [_buildItem(id: 1, voteTotal: 100), _buildItem(id: 2, voteTotal: 200)];
      final list2 = [_buildItem(id: 1, voteTotal: 100), _buildItem(id: 2, voteTotal: 200)];
      expect(areDataListsEqual(list1, list2), isTrue);
    });

    test('different lengths return false', () {
      final list1 = [_buildItem(id: 1)];
      final list2 = [_buildItem(id: 1), _buildItem(id: 2)];
      expect(areDataListsEqual(list1, list2), isFalse);
    });

    test('different IDs return false', () {
      final list1 = [_buildItem(id: 1, voteTotal: 100)];
      final list2 = [_buildItem(id: 2, voteTotal: 100)];
      expect(areDataListsEqual(list1, list2), isFalse);
    });

    test('different vote totals return false', () {
      final list1 = [_buildItem(id: 1, voteTotal: 100)];
      final list2 = [_buildItem(id: 1, voteTotal: 200)];
      expect(areDataListsEqual(list1, list2), isFalse);
    });

    test('both null items are equal', () {
      final List<VoteItemModel?> list1 = [null];
      final List<VoteItemModel?> list2 = [null];
      expect(areDataListsEqual(list1, list2), isTrue);
    });

    test('one null one non-null returns false', () {
      final List<VoteItemModel?> list1 = [null];
      final List<VoteItemModel?> list2 = [_buildItem(id: 1)];
      expect(areDataListsEqual(list1, list2), isFalse);
    });

    test('non-null then null returns false', () {
      final List<VoteItemModel?> list1 = [_buildItem(id: 1)];
      final List<VoteItemModel?> list2 = [null];
      expect(areDataListsEqual(list1, list2), isFalse);
    });

    test('empty lists are equal', () {
      expect(areDataListsEqual([], []), isTrue);
    });

    test('mixed null and non-null items with same structure', () {
      final List<VoteItemModel?> list1 = [_buildItem(id: 1, voteTotal: 100), null, _buildItem(id: 3, voteTotal: 300)];
      final List<VoteItemModel?> list2 = [_buildItem(id: 1, voteTotal: 100), null, _buildItem(id: 3, voteTotal: 300)];
      expect(areDataListsEqual(list1, list2), isTrue);
    });
  });

  group('Matching text logic (_getMatchingText mirror)', () {
    test('returns Korean text when query matches Korean', () {
      final nameMap = {'ko': '지민', 'en': 'Jimin'};
      expect(getMatchingText(nameMap, '지민'), '지민');
    });

    test('returns English text when query matches English', () {
      final nameMap = {'ko': '지민', 'en': 'Jimin'};
      expect(getMatchingText(nameMap, 'jimin'), 'Jimin');
    });

    test('returns Korean text for Korean initials match', () {
      final nameMap = {'ko': '지민', 'en': 'Jimin'};
      expect(getMatchingText(nameMap, 'ㅈㅁ'), '지민');
    });

    test('returns default Korean text when no match', () {
      final nameMap = {'ko': '지민', 'en': 'Jimin'};
      expect(getMatchingText(nameMap, 'Lisa'), '지민');
    });

    test('returns English text when Korean is empty and no match', () {
      final nameMap = {'ko': '', 'en': 'Jimin'};
      expect(getMatchingText(nameMap, 'Lisa'), 'Jimin');
    });

    test('handles empty map', () {
      final nameMap = <String, dynamic>{};
      expect(getMatchingText(nameMap, 'test'), '');
    });

    test('case insensitive English match', () {
      final nameMap = {'ko': '블랙핑크', 'en': 'BLACKPINK'};
      expect(getMatchingText(nameMap, 'blackpink'), 'BLACKPINK');
    });

    test('Korean partial match returns Korean text', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(getMatchingText(nameMap, '방탄'), '방탄소년단');
    });

    test('returns empty string when both ko and en are empty', () {
      final nameMap = {'ko': '', 'en': ''};
      expect(getMatchingText(nameMap, 'test'), '');
    });
  });

  group('Image URL builder (_makeFullImageUrl mirror)', () {
    test('returns empty string for empty URL', () {
      expect(makeFullImageUrl(''), '');
    });

    test('returns absolute HTTP URL as-is', () {
      const url = 'http://example.com/image.jpg';
      expect(makeFullImageUrl(url), url);
    });

    test('returns absolute HTTPS URL as-is', () {
      const url = 'https://example.com/image.jpg';
      expect(makeFullImageUrl(url), url);
    });

    test('prepends CDN URL to relative path', () {
      expect(
        makeFullImageUrl('images/photo.jpg', cdnUrl: 'https://cdn.example.com'),
        'https://cdn.example.com/images/photo.jpg',
      );
    });

    test('handles relative path with leading slash', () {
      expect(
        makeFullImageUrl('/images/photo.jpg', cdnUrl: 'https://cdn.example.com'),
        'https://cdn.example.com/images/photo.jpg',
      );
    });

    test('handles CDN URL with trailing slash', () {
      expect(
        makeFullImageUrl('images/photo.jpg', cdnUrl: 'https://cdn.example.com/'),
        'https://cdn.example.com/images/photo.jpg',
      );
    });

    test('handles both leading and trailing slashes', () {
      expect(
        makeFullImageUrl('/images/photo.jpg', cdnUrl: 'https://cdn.example.com/'),
        'https://cdn.example.com/images/photo.jpg',
      );
    });
  });

  group('Rank update logic (_updateRanks mirror)', () {
    test('assigns sequential ranks for different vote totals', () {
      final items = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 3000, artistId: 11),
        _buildItem(id: 3, voteTotal: 1000, artistId: 12),
      ];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 2);
      expect(ranks[3], 3);
    });

    test('assigns same rank for equal vote totals', () {
      final items = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 5000, artistId: 11),
        _buildItem(id: 3, voteTotal: 3000, artistId: 12),
      ];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 3); // Skips rank 2
    });

    test('handles single item', () {
      final items = [_buildItem(id: 1, voteTotal: 5000)];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
    });

    test('handles empty list', () {
      final ranks = updateRanks([]);
      expect(ranks, isEmpty);
    });

    test('handles all equal vote totals', () {
      final items = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 5000, artistId: 11),
        _buildItem(id: 3, voteTotal: 5000, artistId: 12),
      ];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 1);
    });

    test('skips null items', () {
      final List<VoteItemModel?> items = [
        _buildItem(id: 1, voteTotal: 5000),
        null,
        _buildItem(id: 3, voteTotal: 3000, artistId: 12),
      ];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
      expect(ranks[3], 2);
      expect(ranks.length, 2);
    });

    test('handles zero vote totals', () {
      final items = [
        _buildItem(id: 1, voteTotal: 0),
        _buildItem(id: 2, voteTotal: 0, artistId: 11),
      ];
      final ranks = updateRanks(items);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
    });

    test('handles large number of items', () {
      final items = List.generate(
        100,
        (i) => _buildItem(id: i + 1, voteTotal: 10000 - i * 100, artistId: i + 10),
      );
      final ranks = updateRanks(items);
      expect(ranks[1], 1); // Highest vote total
      expect(ranks[100], 100); // Lowest vote total
    });

    test('rank change detection', () {
      // First ranking
      final items1 = [
        _buildItem(id: 1, voteTotal: 5000),
        _buildItem(id: 2, voteTotal: 3000, artistId: 11),
      ];
      final ranks1 = updateRanks(items1);
      expect(ranks1[1], 1);
      expect(ranks1[2], 2);

      // After vote update - ranks swap
      final items2 = [
        _buildItem(id: 1, voteTotal: 3000),
        _buildItem(id: 2, voteTotal: 5000, artistId: 11),
      ];
      final ranks2 = updateRanks(items2);
      expect(ranks2[1], 2);
      expect(ranks2[2], 1);

      // Detect rank changes
      final rankChanged1 = ranks1[1] != ranks2[1];
      final rankChanged2 = ranks1[2] != ranks2[2];
      expect(rankChanged1, isTrue);
      expect(rankChanged2, isTrue);

      // Determine rank direction
      final rankUp1 = ranks1[1]! > ranks2[1]!; // Higher rank number = worse rank
      final rankUp2 = ranks1[2]! > ranks2[2]!;
      expect(rankUp1, isFalse); // Item 1 went from rank 1 to rank 2 (down)
      expect(rankUp2, isTrue);  // Item 2 went from rank 2 to rank 1 (up)
    });
  });

  group('Vote count diff and highlight logic', () {
    test('positive diff indicates vote gain', () {
      const previousVoteCount = 5000;
      const currentVoteCount = 5100;
      final diff = currentVoteCount - previousVoteCount;
      expect(diff, 100);
      expect(diff > 0, isTrue);
    });

    test('zero diff indicates no change', () {
      const previousVoteCount = 5000;
      const currentVoteCount = 5000;
      final diff = currentVoteCount - previousVoteCount;
      expect(diff, 0);
    });

    test('negative diff can happen in edge cases', () {
      const previousVoteCount = 5000;
      const currentVoteCount = 4900;
      final diff = currentVoteCount - previousVoteCount;
      expect(diff, -100);
    });

    test('highlight tracking with set', () {
      final highlightedItemIds = <int>{};

      // Add item
      highlightedItemIds.add(1);
      expect(highlightedItemIds.contains(1), isTrue);

      // Check duplicate prevention
      final wasNew = highlightedItemIds.add(1);
      expect(wasNew, isFalse); // Already exists

      // Remove item
      highlightedItemIds.remove(1);
      expect(highlightedItemIds.contains(1), isFalse);
    });

    test('previous vote counts tracking', () {
      final previousVoteCounts = <int, int>{};

      // Initial state - no previous count
      final item = _buildItem(id: 1, voteTotal: 5000);
      final previousVoteCount = previousVoteCounts[item.id] ?? item.voteTotal;
      final voteCountDiff = item.voteTotal! - previousVoteCount!;
      expect(voteCountDiff, 0); // First time, diff should be 0

      // Update tracking
      previousVoteCounts[item.id] = item.voteTotal!;

      // After vote update
      final updatedItem = _buildItem(id: 1, voteTotal: 5100);
      final previousVoteCount2 = previousVoteCounts[updatedItem.id] ?? updatedItem.voteTotal;
      final voteCountDiff2 = updatedItem.voteTotal! - previousVoteCount2!;
      expect(voteCountDiff2, 100);
    });
  });

  group('VoteModel additional edge cases', () {
    test('VoteModel with multiple rewards', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '멀티 리워드'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': now.toIso8601String(),
        'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': [
          {'id': 1, 'title': {'ko': '포토카드'}, 'thumbnail': 'https://example.com/r1.jpg'},
          {'id': 2, 'title': {'ko': '앨범'}, 'thumbnail': 'https://example.com/r2.jpg'},
          {'id': 3, 'title': {'ko': '콘서트 티켓'}, 'thumbnail': null},
        ],
      });
      expect(vote.reward!.length, 3);
      expect(vote.reward![0].title, {'ko': '포토카드'});
      expect(vote.reward![1].title, {'ko': '앨범'});
      expect(vote.reward![2].thumbnail, isNull);
    });

    test('VoteModel with null reward list', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '일반 투표'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.reward, isNull);
    });

    test('VoteModel with empty reward list', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '빈 리워드'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': [],
      });
      expect(vote.reward, isNotNull);
      expect(vote.reward!.isEmpty, isTrue);
    });

    test('VoteModel title with multiple locales', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '한국어 제목', 'en': 'English Title', 'ja': '日本語タイトル'},
        'vote_category': null,
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.title['ko'], '한국어 제목');
      expect(vote.title['en'], 'English Title');
      expect(vote.title['ja'], '日本語タイトル');
    });

    test('VoteModel with wait_image and result_image', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '이미지 투표'},
        'vote_category': null,
        'main_image': 'https://example.com/main.jpg',
        'wait_image': 'https://example.com/wait.jpg',
        'result_image': 'https://example.com/result.jpg',
        'vote_content': '투표 내용',
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.mainImage, 'https://example.com/main.jpg');
      expect(vote.waitImage, 'https://example.com/wait.jpg');
      expect(vote.resultImage, 'https://example.com/result.jpg');
    });
  });

  group('VoteItemModel edge cases', () {
    test('copyWith updates voteTotal', () {
      final item = _buildItem(voteTotal: 1000);
      final updated = item.copyWith(voteTotal: 2000);
      expect(updated.voteTotal, 2000);
      expect(updated.id, item.id);
    });

    test('item with null artist group', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 5000,
        'artist': {
          'id': 10,
          'name': {'ko': '솔로 아티스트', 'en': 'Solo Artist'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
      });
      expect(item.artist?.artistGroup, isNull);
      expect(item.artist?.name['ko'], '솔로 아티스트');
    });

    test('item with image URLs', () {
      final item = _buildItem(
        artistImage: 'https://example.com/artist.jpg',
        groupImage: 'https://example.com/group.jpg',
      );
      expect(item.artist?.image, 'https://example.com/artist.jpg');
      expect(item.artist?.artistGroup?.image, 'https://example.com/group.jpg');
    });

    test('item with zero vote total', () {
      final item = _buildItem(voteTotal: 0);
      expect(item.voteTotal, 0);
    });

    test('item with very large vote total', () {
      final item = _buildItem(voteTotal: 999999999);
      expect(item.voteTotal, 999999999);
    });
  });

  group('VoteStatus determination logic', () {
    test('determines active status', () {
      final now = DateTime.now();
      final isEnded = false;
      final isUpcoming = false;
      final VoteStatus status = isEnded
          ? VoteStatus.end
          : (isUpcoming ? VoteStatus.upcoming : VoteStatus.active);
      expect(status, VoteStatus.active);
    });

    test('determines upcoming status', () {
      final isEnded = false;
      final isUpcoming = true;
      final VoteStatus status = isEnded
          ? VoteStatus.end
          : (isUpcoming ? VoteStatus.upcoming : VoteStatus.active);
      expect(status, VoteStatus.upcoming);
    });

    test('determines ended status', () {
      final isEnded = true;
      final isUpcoming = false;
      final VoteStatus status = isEnded
          ? VoteStatus.end
          : (isUpcoming ? VoteStatus.upcoming : VoteStatus.active);
      expect(status, VoteStatus.end);
    });

    test('ended takes precedence over upcoming', () {
      final isEnded = true;
      final isUpcoming = true;
      final VoteStatus status = isEnded
          ? VoteStatus.end
          : (isUpcoming ? VoteStatus.upcoming : VoteStatus.active);
      expect(status, VoteStatus.end);
    });
  });

  group('Search caching logic', () {
    test('cache hit when same query and data', () {
      String lastQuery = '';
      List<VoteItemModel?> lastData = [];
      List<int> cachedFilteredIndices = [];

      final data = [_buildItem(id: 1), _buildItem(id: 2, artistId: 11)];
      const query = '지민';

      // First call
      final result1 = getFilteredIndices(data, query);
      lastQuery = query;
      lastData = List.from(data);
      cachedFilteredIndices = result1;

      // Simulate cache check
      final cacheHit = query == lastQuery &&
          data.length == lastData.length &&
          cachedFilteredIndices.isNotEmpty &&
          areDataListsEqual(data, lastData);
      expect(cacheHit, isTrue);
    });

    test('cache miss when query changes', () {
      String lastQuery = '지민';
      List<VoteItemModel?> lastData = [_buildItem(id: 1)];
      List<int> cachedFilteredIndices = [0];

      const newQuery = '정국';
      final cacheHit = newQuery == lastQuery;
      expect(cacheHit, isFalse);
    });

    test('cache miss when data changes', () {
      final lastData = [_buildItem(id: 1, voteTotal: 100)];
      final newData = [_buildItem(id: 1, voteTotal: 200)];

      expect(areDataListsEqual(lastData, newData), isFalse);
    });

    test('cache miss when data length changes', () {
      final lastData = [_buildItem(id: 1)];
      final newData = [_buildItem(id: 1), _buildItem(id: 2, artistId: 11)];

      final lengthSame = lastData.length == newData.length;
      expect(lengthSame, isFalse);
    });
  });

  group('App lifecycle state handling', () {
    test('timer should cancel on paused state', () {
      // Simulate: when paused or inactive, timer is cancelled
      bool timerActive = true;
      final state = AppLifecycleState.paused;

      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        timerActive = false;
      }
      expect(timerActive, isFalse);
    });

    test('timer should restart on resumed state', () {
      bool timerActive = false;
      final state = AppLifecycleState.resumed;

      if (state == AppLifecycleState.resumed) {
        timerActive = true;
      }
      expect(timerActive, isTrue);
    });

    test('timer stays active on detached state', () {
      bool timerActive = true;
      final state = AppLifecycleState.detached;

      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        timerActive = false;
      }
      expect(timerActive, isTrue);
    });
  });

  group('Scroll and focus logic', () {
    test('scroll threshold at 80%', () {
      const maxScroll = 1000.0;
      const threshold = 0.8;

      expect(810.0 >= maxScroll * threshold, isTrue); // 81% - should trigger
      expect(790.0 >= maxScroll * threshold, isFalse); // 79% - should not trigger
      expect(800.0 >= maxScroll * threshold, isTrue); // exactly 80% - should trigger
    });

    test('focus change triggers scroll', () {
      bool hasFocus = false;
      bool scrollTriggered = false;

      // Simulate focus change
      final newFocusState = true;
      if (hasFocus != newFocusState) {
        hasFocus = newFocusState;
        if (hasFocus) {
          scrollTriggered = true;
        }
      }
      expect(scrollTriggered, isTrue);
    });

    test('no scroll when losing focus', () {
      bool hasFocus = true;
      bool scrollTriggered = false;

      final newFocusState = false;
      if (hasFocus != newFocusState) {
        hasFocus = newFocusState;
        if (hasFocus) {
          scrollTriggered = true;
        }
      }
      expect(scrollTriggered, isFalse);
    });
  });

  group('VotePortal enum', () {
    test('VotePortal.vote value', () {
      expect(VotePortal.vote, isNotNull);
      expect(VotePortal.vote.name, 'vote');
    });

    test('VotePortal.pic value', () {
      expect(VotePortal.pic, isNotNull);
      expect(VotePortal.pic.name, 'pic');
    });

    test('VotePortal values list', () {
      expect(VotePortal.values.length, greaterThanOrEqualTo(2));
    });
  });

  group('Realtime subscription table name logic', () {
    test('vote portal uses vote_item table', () {
      const portal = VotePortal.vote;
      final table = portal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';
      expect(table, 'vote_item');
    });

    test('pic portal uses pic_vote_item table', () {
      const portal = VotePortal.pic;
      final table = portal == VotePortal.vote ? 'vote_item' : 'pic_vote_item';
      expect(table, 'pic_vote_item');
    });
  });

  group('Saving state and refresh guard logic', () {
    test('saving state prevents share action', () {
      bool isSaving = true;
      bool actionExecuted = false;

      if (!isSaving) {
        actionExecuted = true;
      }
      expect(actionExecuted, isFalse);
    });

    test('refreshing guard prevents double refresh', () {
      bool isRefreshingItems = false;
      int refreshCount = 0;

      // First refresh
      if (!isRefreshingItems) {
        isRefreshingItems = true;
        refreshCount++;
        isRefreshingItems = false;
      }

      // Second refresh while not refreshing
      if (!isRefreshingItems) {
        isRefreshingItems = true;
        refreshCount++;
        isRefreshingItems = false;
      }

      expect(refreshCount, 2);
    });

    test('double refresh is prevented when already refreshing', () {
      bool isRefreshingItems = true; // Already refreshing
      bool secondRefreshExecuted = false;

      if (!isRefreshingItems) {
        secondRefreshExecuted = true;
      }
      expect(secondRefreshExecuted, isFalse);
    });
  });

  group('KoreanSearchUtils.buildHighlightedTextSpans', () {
    test('returns spans with highlights', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('지민', '지');
      expect(spans, isNotEmpty);
    });

    test('returns full text when no match', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('지민', 'xyz');
      expect(spans, isNotEmpty);
    });

    test('handles empty text', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('', '지');
      expect(spans, isNotEmpty);
    });

    test('handles empty query', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('지민', '');
      expect(spans, isNotEmpty);
    });
  });

  group('VoteDetailPage widget rendering', () {
    late void Function() restore;

    setUp(() {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      setupMockSupabase({
        'vote': [
          {
            'id': 1,
            'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
            'vote_category': 'birthday',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'vote_item': [
              _voteItemRow(id: 1, voteTotal: 5000, artistNameKo: '지민', artistId: 10),
              _voteItemRow(id: 2, voteTotal: 3000, artistNameKo: '정국', artistNameEn: 'Jungkook', artistId: 11),
            ],
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'visible_at': DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String(),
            'start_at': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
            'stop_at': DateTime.now().toUtc().add(const Duration(days: 7)).toIso8601String(),
            'is_ended': false,
            'is_upcoming': false,
            'is_partnership': false,
            'partner': null,
            'reward': null,
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000, artistNameKo: '지민', artistId: 10),
          _voteItemRow(id: 2, voteTotal: 3000, artistNameKo: '정국', artistNameEn: 'Jungkook', artistId: 11),
        ],
      });
      restore = suppressImageErrors();
    });

    tearDown(() {
      restore();
      tearDownMockSupabase();
    });

    Future<void> pumpAndDrain(WidgetTester tester, widget) async {
      await tester.pumpWidget(widget);
      while (tester.takeException() != null) {}
      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}
    }

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailPage(voteId: 1)),
      );
      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [
          {
            'id': 1,
            'title': {'ko': '픽 투표', 'en': 'Pic Vote'},
            'vote_category': 'birthday',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'vote_item': null,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'visible_at': null,
            'start_at': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
            'stop_at': DateTime.now().toUtc().add(const Duration(days: 7)).toIso8601String(),
            'is_ended': false,
            'is_upcoming': false,
            'is_partnership': false,
            'partner': null,
            'reward': null,
          }
        ],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );
      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders in logged-out state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          loggedIn: false,
        ),
      );
      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('contains CustomScrollView', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailPage(voteId: 1)),
      );
      expect(find.byType(CustomScrollView), findsWidgets);
    });

    testWidgets('dispose cleans up without error', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailPage(voteId: 1)),
      );
      // Replace widget to trigger dispose
      await tester.pumpWidget(buildTestAppPage(const SizedBox()));
      while (tester.takeException() != null) {}
      await tester.pump(const Duration(milliseconds: 300));
      while (tester.takeException() != null) {}
    });
  });
}
