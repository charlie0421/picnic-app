import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

void main() {
  group('CommunityState', () {
    test('기본 생성 - 모든 필드 null', () {
      const state = CommunityState();
      expect(state.currentArtist, isNull);
      expect(state.currentPost, isNull);
      expect(state.currentBoard, isNull);
    });

    test('아티스트 설정 후 copyWith', () {
      final artist = ArtistModel(
        id: 1,
        name: const {'ko': 'BTS'},
      );
      const original = CommunityState();
      final copied = original.copyWith(currentArtist: artist);
      expect(copied.currentArtist, isNotNull);
      expect(copied.currentArtist!.id, equals(1));
      expect(copied.currentPost, isNull); // 기존 null 유지
    });

    test('copyWith - 변경 없으면 동일', () {
      const original = CommunityState();
      final copied = original.copyWith();
      expect(copied.currentArtist, isNull);
      expect(copied.currentPost, isNull);
      expect(copied.currentBoard, isNull);
    });

    test('const 생성자 지원', () {
      const state = CommunityState();
      expect(state, isA<CommunityState>());
    });
  });
}
