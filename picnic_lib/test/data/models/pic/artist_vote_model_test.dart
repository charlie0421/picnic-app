import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';

void main() {
  group('ArtistVoteItemModel', () {
    test('생성 확인', () {
      const item = ArtistVoteItemModel(
        id: 1,
        voteTotal: 500,
        artistVoteId: 10,
        title: {'ko': '최고의 보컬', 'en': 'Best Vocal'},
        description: {'ko': '가장 뛰어난 보컬은?', 'en': 'Who has the best vocal?'},
      );
      expect(item.id, equals(1));
      expect(item.voteTotal, equals(500));
      expect(item.artistVoteId, equals(10));
      expect(item.title['ko'], equals('최고의 보컬'));
      expect(item.description['en'], equals('Who has the best vocal?'));
    });
  });

  group('ArtistMemberModel', () {
    test('생성 확인', () {
      const member = ArtistMemberModel(
        id: 1,
        name: {'ko': '정국', 'en': 'Jungkook'},
        gender: 'male',
        image: 'https://example.com/jk.jpg',
      );
      expect(member.id, equals(1));
      expect(member.name['ko'], equals('정국'));
      expect(member.gender, equals('male'));
      expect(member.image, equals('https://example.com/jk.jpg'));
      expect(member.artistGroup, isNull);
    });

    test('이미지 null 허용', () {
      const member = ArtistMemberModel(
        id: 2,
        name: {'ko': '뷔'},
        gender: 'male',
        image: null,
      );
      expect(member.image, isNull);
    });
  });

  group('MyStarGroupModel', () {
    test('생성 확인', () {
      const group = MyStarGroupModel(
        id: 1,
        nameKo: '방탄소년단',
        nameEn: 'BTS',
      );
      expect(group.id, equals(1));
      expect(group.nameKo, equals('방탄소년단'));
      expect(group.nameEn, equals('BTS'));
      expect(group.image, isNull);
    });

    test('이미지 포함', () {
      const group = MyStarGroupModel(
        id: 2,
        nameKo: '에스파',
        nameEn: 'aespa',
        image: 'https://example.com/group.jpg',
      );
      expect(group.image, isNotNull);
    });
  });

  group('MyStarMemberModel', () {
    test('생성 확인', () {
      const member = MyStarMemberModel(
        id: 1,
        nameKo: '윈터',
        nameEn: 'Winter',
        gender: 'female',
        image: 'https://example.com/winter.jpg',
      );
      expect(member.id, equals(1));
      expect(member.nameKo, equals('윈터'));
      expect(member.nameEn, equals('Winter'));
      expect(member.gender, equals('female'));
      expect(member.mystarGroup, isNull);
    });

    test('그룹 포함', () {
      const group = MyStarGroupModel(
        id: 1,
        nameKo: '에스파',
        nameEn: 'aespa',
      );
      const member = MyStarMemberModel(
        id: 1,
        nameKo: '카리나',
        nameEn: 'Karina',
        gender: 'female',
        image: null,
        mystarGroup: group,
      );
      expect(member.mystarGroup, isNotNull);
      expect(member.mystarGroup!.nameKo, equals('에스파'));
    });
  });

  group('ArtistVoteModel', () {
    test('필수 필드로 생성', () {
      final vote = ArtistVoteModel(
        id: 1,
        title: {'ko': '최고의 아티스트', 'en': 'Best Artist'},
        category: 'music',
        artistVoteItem: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: null,
        visibleAt: null,
        stopAt: DateTime(2025, 3, 1),
        startAt: DateTime(2025, 2, 1),
      );
      expect(vote.id, equals(1));
      expect(vote.title['ko'], equals('최고의 아티스트'));
      expect(vote.category, equals('music'));
      expect(vote.artistVoteItem, isNull);
      expect(vote.updatedAt, isNull);
      expect(vote.visibleAt, isNull);
    });

    test('투표 아이템 포함', () {
      const item1 = ArtistVoteItemModel(
        id: 10,
        voteTotal: 500,
        artistVoteId: 1,
        title: {'ko': '옵션A'},
        description: {'ko': '설명A'},
      );
      const item2 = ArtistVoteItemModel(
        id: 11,
        voteTotal: 300,
        artistVoteId: 1,
        title: {'ko': '옵션B'},
        description: {'ko': '설명B'},
      );

      final vote = ArtistVoteModel(
        id: 1,
        title: {'ko': '투표'},
        category: 'idol',
        artistVoteItem: [item1, item2],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 2, 1),
        visibleAt: DateTime(2025, 1, 15),
        stopAt: DateTime(2025, 3, 1),
        startAt: DateTime(2025, 2, 1),
      );
      expect(vote.artistVoteItem!.length, equals(2));
      expect(vote.artistVoteItem![0].voteTotal, equals(500));
      expect(vote.artistVoteItem![1].voteTotal, equals(300));
    });

    test('날짜 순서 확인', () {
      final vote = ArtistVoteModel(
        id: 2,
        title: {'ko': '테스트'},
        category: 'test',
        artistVoteItem: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 15),
        visibleAt: DateTime(2025, 1, 10),
        stopAt: DateTime(2025, 3, 1),
        startAt: DateTime(2025, 2, 1),
      );
      expect(vote.startAt.isBefore(vote.stopAt), isTrue);
      expect(vote.createdAt.isBefore(vote.startAt), isTrue);
    });
  });

  group('ArtistGroupModel (pic)', () {
    test('필수 필드로 생성', () {
      const group = ArtistGroupModel(
        id: 1,
        name: {'ko': '그룹명', 'en': 'Group Name'},
      );
      expect(group.id, equals(1));
      expect(group.name['ko'], equals('그룹명'));
      expect(group.image, isNull);
    });

    test('이미지 포함', () {
      const group = ArtistGroupModel(
        id: 2,
        name: {'ko': 'BTS', 'en': 'BTS'},
        image: 'group.jpg',
      );
      expect(group.image, equals('group.jpg'));
    });
  });
}
