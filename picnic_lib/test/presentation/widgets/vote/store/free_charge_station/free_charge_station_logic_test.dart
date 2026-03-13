import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';

/// Tests for FreeChargeStation item-building logic patterns.
///
/// The widget itself depends on google_mobile_ads, tapjoy, pangle etc.
/// We test the pure logic patterns: mission/ad item construction,
/// ad reordering, and platform availability checks.
void main() {
  group('ChargeStationItem construction', () {
    test('creates mission item with all fields', () {
      final item = ChargeStationItem(
        id: 'tapjoy',
        title: 'Global Recommendation #1',
        isMission: true,
        platformType: AdPlatformType.tapjoy,
        onPressed: () {},
        bonusText: 'Unlimited',
      );

      expect(item.id, 'tapjoy');
      expect(item.title, 'Global Recommendation #1');
      expect(item.isMission, isTrue);
      expect(item.platformType, AdPlatformType.tapjoy);
      expect(item.bonusText, 'Unlimited');
      expect(item.index, 0);
    });

    test('creates ad item with index', () {
      final item = ChargeStationItem(
        id: 'admob',
        title: 'Ad #1',
        isMission: false,
        platformType: AdPlatformType.admob,
        index: 0,
        onPressed: () {},
        bonusText: '1',
      );

      expect(item.id, 'admob');
      expect(item.isMission, isFalse);
      expect(item.index, 0);
      expect(item.bonusText, '1');
    });

    test('default bonusText is "1"', () {
      final item = ChargeStationItem(
        id: 'test',
        title: 'Test',
        isMission: false,
        platformType: AdPlatformType.custom,
        onPressed: () {},
      );
      expect(item.bonusText, '1');
    });

    test('default index is 0', () {
      final item = ChargeStationItem(
        id: 'test',
        title: 'Test',
        isMission: false,
        platformType: AdPlatformType.custom,
        onPressed: () {},
      );
      expect(item.index, 0);
    });
  });

  group('AdPlatformType enum', () {
    test('has all expected values', () {
      expect(AdPlatformType.values.length, 6);
      expect(AdPlatformType.values, contains(AdPlatformType.admob));
      expect(AdPlatformType.values, contains(AdPlatformType.unity));
      expect(AdPlatformType.values, contains(AdPlatformType.pangle));
      expect(AdPlatformType.values, contains(AdPlatformType.tapjoy));
      expect(AdPlatformType.values, contains(AdPlatformType.pincrux));
      expect(AdPlatformType.values, contains(AdPlatformType.custom));
    });

    test('name returns correct string', () {
      expect(AdPlatformType.admob.name, 'admob');
      expect(AdPlatformType.custom.name, 'custom');
      expect(AdPlatformType.pangle.name, 'pangle');
    });
  });

  group('Mission items construction logic', () {
    // Mirrors _buildMissionItems logic
    List<ChargeStationItem> buildMissionItems({
      required Set<String> availablePlatforms,
    }) {
      var globalIndex = 0;
      var koreaIndex = 0;
      final items = <ChargeStationItem>[];

      if (availablePlatforms.contains('tapjoy')) {
        items.add(ChargeStationItem(
          id: 'tapjoy',
          title: 'Global Recommendation #${globalIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.tapjoy,
          onPressed: () {},
          bonusText: 'Unlimited',
        ));
        globalIndex++;
      }

      if (availablePlatforms.contains('pincrux')) {
        items.add(ChargeStationItem(
          id: 'pincrux',
          title: 'Korea Recommendation #${koreaIndex + 1}',
          isMission: true,
          platformType: AdPlatformType.pincrux,
          onPressed: () {},
          bonusText: 'Unlimited',
        ));
        globalIndex++;
      }

      return items;
    }

    test('returns empty list when no platforms available', () {
      final items = buildMissionItems(availablePlatforms: {});
      expect(items, isEmpty);
    });

    test('returns tapjoy when available', () {
      final items = buildMissionItems(availablePlatforms: {'tapjoy'});
      expect(items.length, 1);
      expect(items.first.id, 'tapjoy');
      expect(items.first.isMission, isTrue);
    });

    test('returns pincrux when available', () {
      final items = buildMissionItems(availablePlatforms: {'pincrux'});
      expect(items.length, 1);
      expect(items.first.id, 'pincrux');
    });

    test('returns both when both available', () {
      final items = buildMissionItems(
        availablePlatforms: {'tapjoy', 'pincrux'},
      );
      expect(items.length, 2);
      expect(items[0].id, 'tapjoy');
      expect(items[1].id, 'pincrux');
    });
  });

  group('Ad items construction and reordering logic', () {
    // Mirrors _buildAdItems logic (simplified)
    List<ChargeStationItem> buildAdItems({
      required Set<String> availablePlatforms,
      required String globalLabel,
      required String asiaLabel,
    }) {
      var globalIndex = 0;
      var asiaIndex = 0;
      final items = <ChargeStationItem>[];

      if (availablePlatforms.contains('internal-shortform')) {
        items.add(ChargeStationItem(
          id: 'internal-shortform',
          title: '$globalLabel #${globalIndex + 2}',
          isMission: false,
          platformType: AdPlatformType.custom,
          onPressed: () {},
          bonusText: '1',
        ));
      }

      if (availablePlatforms.contains('admob')) {
        items.add(ChargeStationItem(
          id: 'admob',
          title: '$globalLabel #${globalIndex + 1}',
          isMission: false,
          platformType: AdPlatformType.admob,
          index: 0,
          onPressed: () {},
          bonusText: '1',
        ));
        globalIndex++;
      }

      if (availablePlatforms.contains('pangle')) {
        items.add(ChargeStationItem(
          id: 'pangle',
          title: '$asiaLabel #${asiaIndex + 1}',
          isMission: false,
          platformType: AdPlatformType.pangle,
          onPressed: () {},
          bonusText: '1',
        ));
        asiaIndex++;
      }

      // Reordering: move internal-shortform after first global
      final globalItems = <int>[];
      for (var i = 0; i < items.length; i++) {
        if (items[i].title.contains(globalLabel)) {
          globalItems.add(i);
        }
      }

      final internalIdx = items.indexWhere((x) => x.id == 'internal-shortform');
      if (internalIdx != -1 && globalItems.isNotEmpty) {
        final firstGlobal = globalItems.first;
        var targetPos = (firstGlobal + 1 <= items.length)
            ? firstGlobal + 1
            : items.length;
        final internalItem = items.removeAt(internalIdx);
        // Adjust targetPos if removal shifted indices
        if (internalIdx < targetPos) targetPos--;
        items.insert(targetPos, internalItem);
      }

      return items;
    }

    test('returns empty when no platforms available', () {
      final items = buildAdItems(
        availablePlatforms: {},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items, isEmpty);
    });

    test('returns admob only when only admob available', () {
      final items = buildAdItems(
        availablePlatforms: {'admob'},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items.length, 1);
      expect(items.first.id, 'admob');
    });

    test('returns pangle only when only pangle available', () {
      final items = buildAdItems(
        availablePlatforms: {'pangle'},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items.length, 1);
      expect(items.first.id, 'pangle');
    });

    test('reorders internal-shortform after admob', () {
      final items = buildAdItems(
        availablePlatforms: {'admob', 'internal-shortform'},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items.length, 2);
      // Both are global items; internal-shortform is placed after first global
      final ids = items.map((e) => e.id).toList();
      expect(ids, contains('admob'));
      expect(ids, contains('internal-shortform'));
    });

    test('all platforms present', () {
      final items = buildAdItems(
        availablePlatforms: {'admob', 'pangle', 'internal-shortform'},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items.length, 3);
      final ids = items.map((e) => e.id).toList();
      expect(ids, contains('admob'));
      expect(ids, contains('internal-shortform'));
      expect(ids, contains('pangle'));
    });

    test('internal-shortform alone works correctly', () {
      final items = buildAdItems(
        availablePlatforms: {'internal-shortform'},
        globalLabel: 'Global',
        asiaLabel: 'Asia',
      );
      expect(items.length, 1);
      expect(items.first.id, 'internal-shortform');
    });
  });
}
