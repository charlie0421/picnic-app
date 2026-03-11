import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

void main() {
  group('VoteStatus', () {
    test('6개 상태 존재', () {
      expect(VoteStatus.values.length, equals(6));
    });

    test('모든 상태 확인', () {
      expect(VoteStatus.all, isNotNull);
      expect(VoteStatus.active, isNotNull);
      expect(VoteStatus.end, isNotNull);
      expect(VoteStatus.upcoming, isNotNull);
      expect(VoteStatus.activeAndUpcoming, isNotNull);
      expect(VoteStatus.debug, isNotNull);
    });

    test('name 속성', () {
      expect(VoteStatus.all.name, equals('all'));
      expect(VoteStatus.active.name, equals('active'));
      expect(VoteStatus.end.name, equals('end'));
      expect(VoteStatus.upcoming.name, equals('upcoming'));
      expect(VoteStatus.activeAndUpcoming.name, equals('activeAndUpcoming'));
      expect(VoteStatus.debug.name, equals('debug'));
    });
  });

  group('VoteCategory', () {
    test('7개 카테고리 존재', () {
      expect(VoteCategory.values.length, equals(7));
    });

    test('모든 카테고리 확인', () {
      expect(VoteCategory.all, isNotNull);
      expect(VoteCategory.birthday, isNotNull);
      expect(VoteCategory.comeback, isNotNull);
      expect(VoteCategory.achieve, isNotNull);
      expect(VoteCategory.birth, isNotNull);
      expect(VoteCategory.debut, isNotNull);
      expect(VoteCategory.image, isNotNull);
    });

    test('name 속성', () {
      expect(VoteCategory.birthday.name, equals('birthday'));
      expect(VoteCategory.comeback.name, equals('comeback'));
      expect(VoteCategory.image.name, equals('image'));
    });
  });

  group('VotePortal', () {
    test('2개 포털 존재', () {
      expect(VotePortal.values.length, equals(2));
    });

    test('모든 포털 확인', () {
      expect(VotePortal.vote.name, equals('vote'));
      expect(VotePortal.pic.name, equals('pic'));
    });
  });
}
