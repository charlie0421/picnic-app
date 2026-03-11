import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';

void main() {
  group('CommunityState', () {
    test('default values are null', () {
      const state = CommunityState();
      expect(state.currentArtist, isNull);
      expect(state.currentPost, isNull);
      expect(state.currentBoard, isNull);
    });

    test('copyWith with no arguments returns same values', () {
      const state = CommunityState();
      final copied = state.copyWith();
      expect(copied.currentArtist, isNull);
      expect(copied.currentPost, isNull);
      expect(copied.currentBoard, isNull);
    });
  });
}
