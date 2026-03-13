import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete_helper.dart';

void main() {
  group('VotingCompleteHelper.parseUpdatedAt', () {
    test('parses valid ISO-8601 date string', () {
      final result = VotingCompleteHelper.parseUpdatedAt({
        'updatedAt': '2025-06-15T10:30:00.000Z',
      });
      expect(result.year, 2025);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('returns DateTime.now() when updatedAt is null', () {
      final before = DateTime.now();
      final result = VotingCompleteHelper.parseUpdatedAt({});
      final after = DateTime.now();

      expect(result.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('returns DateTime.now() when updatedAt key is missing', () {
      final before = DateTime.now();
      final result = VotingCompleteHelper.parseUpdatedAt({'other': 'value'});
      final after = DateTime.now();

      expect(result.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('returns DateTime.now() when updatedAt is invalid string', () {
      final before = DateTime.now();
      final result = VotingCompleteHelper.parseUpdatedAt({
        'updatedAt': 'not-a-date',
      });
      final after = DateTime.now();

      expect(result.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('parses date without time zone', () {
      final result = VotingCompleteHelper.parseUpdatedAt({
        'updatedAt': '2024-12-25T00:00:00',
      });
      expect(result.year, 2024);
      expect(result.month, 12);
      expect(result.day, 25);
    });
  });

  group('VotingCompleteHelper.extractAddedVoteTotal', () {
    test('extracts integer value', () {
      expect(
        VotingCompleteHelper.extractAddedVoteTotal({'addedVoteTotal': 42}),
        42,
      );
    });

    test('extracts double value as int', () {
      expect(
        VotingCompleteHelper.extractAddedVoteTotal({'addedVoteTotal': 42.7}),
        42,
      );
    });

    test('returns 0 when key is missing', () {
      expect(
        VotingCompleteHelper.extractAddedVoteTotal({}),
        0,
      );
    });

    test('returns 0 when value is null', () {
      expect(
        VotingCompleteHelper.extractAddedVoteTotal({'addedVoteTotal': null}),
        0,
      );
    });

    test('handles large numbers', () {
      expect(
        VotingCompleteHelper.extractAddedVoteTotal({'addedVoteTotal': 999999}),
        999999,
      );
    });
  });

  group('VotingCompleteHelper.shouldShowArtist', () {
    test('returns true for non-zero id', () {
      expect(VotingCompleteHelper.shouldShowArtist(10), isTrue);
    });

    test('returns false for zero id', () {
      expect(VotingCompleteHelper.shouldShowArtist(0), isFalse);
    });

    test('returns false for null id', () {
      expect(VotingCompleteHelper.shouldShowArtist(null), isFalse);
    });

    test('returns true for negative id', () {
      // Negative IDs are non-zero, so they count as "has artist"
      expect(VotingCompleteHelper.shouldShowArtist(-1), isTrue);
    });
  });
}
