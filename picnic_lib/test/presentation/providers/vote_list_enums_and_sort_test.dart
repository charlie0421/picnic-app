import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

void main() {
  group('VoteStatus', () {
    test('has all expected values', () {
      expect(VoteStatus.values.length, 6);
      expect(VoteStatus.values, contains(VoteStatus.all));
      expect(VoteStatus.values, contains(VoteStatus.active));
      expect(VoteStatus.values, contains(VoteStatus.end));
      expect(VoteStatus.values, contains(VoteStatus.upcoming));
      expect(VoteStatus.values, contains(VoteStatus.activeAndUpcoming));
      expect(VoteStatus.values, contains(VoteStatus.debug));
    });
  });

  group('VoteCategory', () {
    test('has all expected values', () {
      expect(VoteCategory.values.length, 7);
      expect(VoteCategory.values, contains(VoteCategory.all));
      expect(VoteCategory.values, contains(VoteCategory.birthday));
      expect(VoteCategory.values, contains(VoteCategory.comeback));
      expect(VoteCategory.values, contains(VoteCategory.achieve));
      expect(VoteCategory.values, contains(VoteCategory.birth));
      expect(VoteCategory.values, contains(VoteCategory.debut));
      expect(VoteCategory.values, contains(VoteCategory.image));
    });

    test('name returns lowercase string', () {
      expect(VoteCategory.birthday.name, 'birthday');
      expect(VoteCategory.achieve.name, 'achieve');
    });
  });

  group('VotePortal', () {
    test('has all expected values', () {
      expect(VotePortal.values.length, 2);
      expect(VotePortal.values, contains(VotePortal.vote));
      expect(VotePortal.values, contains(VotePortal.pic));
    });
  });

  group('SortOptionType', () {
    test('constructor sets sort and order', () {
      final opt = SortOptionType('id', 'DESC');
      expect(opt.sort, 'id');
      expect(opt.order, 'DESC');
    });

    test('fields are mutable', () {
      final opt = SortOptionType('id', 'DESC');
      opt.sort = 'created_at';
      opt.order = 'ASC';
      expect(opt.sort, 'created_at');
      expect(opt.order, 'ASC');
    });
  });
}
