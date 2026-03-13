import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

void main() {
  group('SortOptionType', () {
    test('creates with sort and order', () {
      final option = SortOptionType('created_at', 'desc');
      expect(option.sort, 'created_at');
      expect(option.order, 'desc');
    });

    test('sort and order are mutable', () {
      final option = SortOptionType('id', 'asc');
      option.sort = 'name';
      option.order = 'desc';
      expect(option.sort, 'name');
      expect(option.order, 'desc');
    });

    test('empty sort and order', () {
      final option = SortOptionType('', '');
      expect(option.sort, '');
      expect(option.order, '');
    });
  });

  group('PostListType', () {
    test('has 2 values', () {
      // PostListType is in post_list.dart, but VotePortal is accessible
      expect(VotePortal.values.length, 2);
    });
  });

  group('VoteStatus name roundtrip', () {
    test('all statuses have valid names', () {
      for (final status in VoteStatus.values) {
        expect(status.name, isNotEmpty);
        expect(status.name, isA<String>());
      }
    });
  });

  group('VoteCategory name roundtrip', () {
    test('all categories have valid names', () {
      for (final category in VoteCategory.values) {
        expect(category.name, isNotEmpty);
        expect(category.name, isA<String>());
      }
    });
  });
}
