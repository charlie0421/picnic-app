import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';

/// KST wall-clock instant, expressed as a UTC [DateTime] with the KST clock
/// fields (matches how the production V2 timestamps are decoded: always an
/// absolute instant, displayed/reasoned about in KST).
DateTime kst(int y, int m, int d, [int h = 0, int mi = 0, int s = 0]) =>
    DateTime.utc(y, m, d, h, mi, s).subtract(const Duration(hours: 9));

void main() {
  group('resolveActiveBoostOccurrence', () {
    test(
      'Mon-Wed weekly: Sep22 (Tue) resolves to the Sep21-23 occurrence',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 21),
          eventEndsAt: kst(2027, 1, 1),
          repeatIsoDows: const [1, 2, 3],
          snapshotAt: kst(2026, 9, 22, 10),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 9, 21));
        expect(result.end, kst(2026, 9, 24));
      },
    );

    test('Mon-Wed weekly: Sep29 (Tue) resolves to the Sep28-30 occurrence', () {
      final result = resolveActiveBoostOccurrence(
        eventStartsAt: kst(2026, 9, 21),
        eventEndsAt: kst(2027, 1, 1),
        repeatIsoDows: const [1, 2, 3],
        snapshotAt: kst(2026, 9, 29, 10),
      );
      expect(result, isNotNull);
      expect(result!.start, kst(2026, 9, 28));
      expect(result.end, kst(2026, 10, 1));
    });

    test(
      'Mon-Wed weekly: Dec29 (Tue) resolves to Dec28-30, staying contiguous '
      'across the year boundary and clipped by the campaign end',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 21),
          eventEndsAt: kst(2027, 1, 1),
          repeatIsoDows: const [1, 2, 3],
          snapshotAt: kst(2026, 12, 29, 10),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 12, 28));
        expect(result.end, kst(2026, 12, 31));
      },
    );

    test('snapshot before the campaign start resolves to no period', () {
      final result = resolveActiveBoostOccurrence(
        eventStartsAt: kst(2026, 9, 21),
        eventEndsAt: kst(2027, 1, 1),
        repeatIsoDows: const [1, 2, 3],
        snapshotAt: kst(2026, 9, 20, 23, 59, 59),
      );
      expect(result, isNull);
    });

    test(
      'snapshot exactly at the exclusive campaign end resolves to no period '
      '(does not invent a next occurrence)',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 21),
          eventEndsAt: kst(2027, 1, 1),
          repeatIsoDows: const [1, 2, 3],
          snapshotAt: kst(2027, 1, 1),
        );
        expect(result, isNull);
      },
    );

    test(
      'snapshot on an inactive weekday resolves to no period (does not '
      'invent the next occurrence)',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 21),
          eventEndsAt: kst(2027, 1, 1),
          repeatIsoDows: const [1, 2, 3],
          // Sep24 2026 is a Thursday.
          snapshotAt: kst(2026, 9, 24, 10),
        );
        expect(result, isNull);
      },
    );

    test(
      'a run crossing Sunday/Monday stays contiguous (Sat/Sun/Mon repeat)',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 1),
          eventEndsAt: kst(2026, 12, 1),
          repeatIsoDows: const [1, 6, 7],
          // Sep20 2026 is a Sunday, sandwiched between Sat19 and Mon21.
          snapshotAt: kst(2026, 9, 20, 12),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 9, 19));
        expect(result.end, kst(2026, 9, 22));
      },
    );

    test(
      'clips the first partial day to the actual campaign start timestamp',
      () {
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 9, 21, 15, 30),
          eventEndsAt: kst(2027, 1, 1),
          repeatIsoDows: const [1, 2, 3],
          snapshotAt: kst(2026, 9, 21, 20),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 9, 21, 15, 30));
        expect(result.end, kst(2026, 9, 24));
      },
    );

    test('clips the last partial day to the actual campaign end timestamp', () {
      final result = resolveActiveBoostOccurrence(
        eventStartsAt: kst(2026, 9, 21),
        eventEndsAt: kst(2026, 9, 23, 14, 0),
        repeatIsoDows: const [1, 2, 3],
        snapshotAt: kst(2026, 9, 23, 10),
      );
      expect(result, isNotNull);
      expect(result!.start, kst(2026, 9, 21));
      expect(result.end, kst(2026, 9, 23, 14, 0));
    });

    test(
      'all 7 ISO weekdays repeating: the occurrence is bounded to the '
      'current KST Monday-to-next-Monday calendar week, not the whole '
      'campaign envelope',
      () {
        // 2026-06-15 is a Monday, so the containing week is exactly
        // Jun15-Jun22 (exclusive) with no clipping needed.
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 1, 1),
          eventEndsAt: kst(2026, 12, 31),
          repeatIsoDows: const [1, 2, 3, 4, 5, 6, 7],
          snapshotAt: kst(2026, 6, 15, 10),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 6, 15));
        expect(result.end, kst(2026, 6, 22));
      },
    );

    test(
      'all 7 ISO weekdays repeating: a snapshot mid-week resolves to that '
      "week's Monday-to-next-Monday bounds",
      () {
        // 2026-06-17 is a Wednesday; the containing week is Jun15-Jun22.
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 1, 1),
          eventEndsAt: kst(2026, 12, 31),
          repeatIsoDows: const [1, 2, 3, 4, 5, 6, 7],
          snapshotAt: kst(2026, 6, 17, 10),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 6, 15));
        expect(result.end, kst(2026, 6, 22));
      },
    );

    test(
      'all 7 ISO weekdays repeating: the first partial calendar week is '
      'clipped to the actual campaign start',
      () {
        // 2026-06-17 (Wed) is in the Jun15-Jun22 calendar week, but the
        // campaign only starts Jun17 15:00 KST, so the resolved start must
        // not reach back to the Monday before the campaign existed.
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 6, 17, 15),
          eventEndsAt: kst(2026, 12, 31),
          repeatIsoDows: const [1, 2, 3, 4, 5, 6, 7],
          snapshotAt: kst(2026, 6, 17, 20),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 6, 17, 15));
        expect(result.end, kst(2026, 6, 22));
      },
    );

    test(
      'all 7 ISO weekdays repeating: the last partial calendar week is '
      'clipped to the actual campaign end',
      () {
        // 2026-06-17 (Wed) is in the Jun15-Jun22 calendar week, but the
        // campaign ends Jun18 12:00 KST, so the resolved end must not reach
        // forward past the campaign's actual last instant.
        final result = resolveActiveBoostOccurrence(
          eventStartsAt: kst(2026, 1, 1),
          eventEndsAt: kst(2026, 6, 18, 12),
          repeatIsoDows: const [1, 2, 3, 4, 5, 6, 7],
          snapshotAt: kst(2026, 6, 17, 10),
        );
        expect(result, isNotNull);
        expect(result!.start, kst(2026, 6, 15));
        expect(result.end, kst(2026, 6, 18, 12));
      },
    );

    test('single-day repeat (only Wednesdays) resolves to just that day', () {
      final result = resolveActiveBoostOccurrence(
        eventStartsAt: kst(2026, 9, 1),
        eventEndsAt: kst(2026, 12, 1),
        repeatIsoDows: const [3],
        // Sep23 2026 is a Wednesday; Sep16 and Sep30 are Wednesdays too but
        // are not adjacent days, so they must not merge into this run.
        snapshotAt: kst(2026, 9, 23, 10),
      );
      expect(result, isNotNull);
      expect(result!.start, kst(2026, 9, 23));
      expect(result.end, kst(2026, 9, 24));
    });
  });
}
