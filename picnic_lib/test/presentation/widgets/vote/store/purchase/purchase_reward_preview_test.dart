import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview.dart';

BigInt big(int value) => BigInt.from(value);

void main() {
  group('exact V2 multiplier math', () {
    test('STAR100 under a 2x campaign previews base 100 + event 100 = 200', () {
      final preview = PurchaseRewardPreview(
        base: big(100),
        productBonus: BigInt.zero,
        multiplierTenths: 20,
      );

      expect(preview.base, big(100));
      expect(preview.productBonus, BigInt.zero);
      expect(preview.eventBonus, big(100));
      expect(preview.expectedTotal, big(200));
      expect(preview.totalMultiplierTenths, 20);
    });

    test('STAR200 under a 2x campaign previews 200 + 25 + event 225 = 450', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        multiplierTenths: 20,
      );

      // The event bonus is computed on the whole catalog reward (225), not
      // on the star amount alone.
      expect(preview.baseTotal, big(225));
      expect(preview.eventBonus, big(225));
      expect(preview.expectedTotal, big(450));
      expect(preview.totalMultiplierTenths, 20);
    });

    test('1.5x floors the gross and never rounds the extra up', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        multiplierTenths: 15,
      );

      // floor(225 * 15 / 10) = 337, so the extra is 112 - not 112.5 or 113.
      expect(preview.eventBonus, big(112));
      expect(preview.expectedTotal, big(337));
      expect(preview.totalMultiplierTenths, 15);
    });

    test('1.1x on a floored total still reads as a 1.1x pill', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        multiplierTenths: 11,
      );

      expect(preview.eventBonus, big(22));
      expect(preview.expectedTotal, big(247));
      expect(preview.totalMultiplierTenths, 11);
    });

    test('3x triples the catalog reward', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        multiplierTenths: 30,
      );

      expect(preview.eventBonus, big(450));
      expect(preview.expectedTotal, big(675));
      expect(preview.totalMultiplierTenths, 30);
    });

    test('a multiplier that floors back to the base still grants one', () {
      // floor(1 * 11 / 10) = 1, which would be a zero bonus; the contract
      // guarantees max(baseTotal + 1, ...).
      final preview = PurchaseRewardPreview(
        base: BigInt.one,
        productBonus: BigInt.zero,
        multiplierTenths: 11,
      );

      expect(preview.eventBonus, BigInt.one);
      expect(preview.expectedTotal, big(2));
    });

    test('the pill states the campaign multiplier, not the floored ratio', () {
      // floor(225 * 15 / 10) = 337 actually pays 1.4977…x. The campaign is
      // 1.5x and that is what the pill says; the exact amounts are printed
      // right next to it.
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        multiplierTenths: 15,
      );

      expect(preview.expectedTotal, big(337));
      expect(preview.totalMultiplierTenths, 15);
    });

    test('the minimum-increment case never inflates the pill', () {
      // 1 candy at 1.1x pays 2 because of the +1 guarantee - a 2x ratio. The
      // campaign is still 1.1x, and a pill claiming 2x would advertise a
      // campaign that does not exist.
      final preview = PurchaseRewardPreview(
        base: BigInt.one,
        productBonus: BigInt.zero,
        multiplierTenths: 11,
      );

      expect(preview.eventBonus, BigInt.one);
      expect(preview.totalMultiplierTenths, 11);
    });

    for (final tenths in [10, 31, 0, -5]) {
      test('an out-of-range multiplier ($tenths) invents no bonus', () {
        final preview = PurchaseRewardPreview(
          base: big(100),
          productBonus: BigInt.zero,
          multiplierTenths: tenths,
        );

        expect(preview.eventBonus, BigInt.zero);
        expect(preview.expectedTotal, big(100));
        expect(preview.totalMultiplierTenths, isNull);
      });
    }
  });

  group('V1 basis-point math', () {
    test('an exact-double record doubles the catalog reward', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
        extraBonusBps: 10000,
      );

      expect(preview.eventBonus, big(225));
      expect(preview.expectedTotal, big(450));
      expect(preview.totalMultiplierTenths, 20);
    });

    test('V1 floors to zero and is not lifted to a minimum of one', () {
      // V1 has no max(baseTotal + 1, ...) guarantee: floor(100 / 10000) = 0.
      final preview = PurchaseRewardPreview(
        base: big(100),
        productBonus: BigInt.zero,
        extraBonusBps: 1,
      );

      expect(preview.eventBonus, BigInt.zero);
      expect(preview.hasEventBonus, isFalse);
      expect(preview.totalMultiplierTenths, isNull);
    });

    test('a 15% record floors the fraction away instead of rounding it up', () {
      // 101 * 1500 / 10000 = 15.15. Rounding that to 16 would advertise one
      // candy more than the settlement will grant.
      final preview = PurchaseRewardPreview(
        base: big(100),
        productBonus: BigInt.one,
        extraBonusBps: 1500,
      );

      expect(preview.baseTotal, big(101));
      expect(preview.eventBonus, big(15));
      expect(preview.expectedTotal, big(116));
    });

    test('a 15% record advertises no multiplier pill at all', () {
      // 100 -> 115 is a 1.15x total. One decimal can only say 1.1x (less than
      // the user gets) or 1.2x (more than the settlement will grant); the
      // second is a promise this app cannot keep, so a record whose total is
      // not an exact tenth gets no pill and shows its +15 instead.
      final preview = PurchaseRewardPreview(
        base: big(100),
        productBonus: BigInt.zero,
        extraBonusBps: 1500,
      );

      expect(preview.eventBonus, big(15));
      expect(preview.expectedTotal, big(115));
      expect(preview.hasEventBonus, isTrue);
      expect(preview.totalMultiplierTenths, isNull);
    });

    test('a 50% record is an exact tenth and keeps its pill', () {
      // 5000bps is a 1.5x total exactly, which one decimal can state.
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: BigInt.zero,
        extraBonusBps: 5000,
      );

      expect(preview.eventBonus, big(100));
      expect(preview.expectedTotal, big(300));
      expect(preview.totalMultiplierTenths, 15);
    });

    test('an exact V2 multiplier wins over a V1 basis-point value', () {
      final preview = PurchaseRewardPreview(
        base: big(100),
        productBonus: BigInt.zero,
        multiplierTenths: 20,
        extraBonusBps: 2500,
      );

      expect(preview.eventBonus, big(100));
    });

    test('a bonus too small to change the pill hides the pill', () {
      // floor(20000 * 1 / 10000) = 2: a real bonus, but a 1.0001x total is
      // not a tenth any pill can state, so only the +amount is shown.
      final preview = PurchaseRewardPreview(
        base: big(20000),
        productBonus: BigInt.zero,
        extraBonusBps: 1,
      );

      expect(preview.eventBonus, big(2));
      expect(preview.hasEventBonus, isTrue);
      expect(preview.totalMultiplierTenths, isNull);
    });
  });

  group('malformed input invents no bonus', () {
    test('no campaign leaves the catalog reward alone', () {
      final preview = PurchaseRewardPreview(
        base: big(200),
        productBonus: big(25),
      );

      expect(preview.eventBonus, BigInt.zero);
      expect(preview.hasEventBonus, isFalse);
      expect(preview.expectedTotal, big(225));
      expect(preview.totalMultiplierTenths, isNull);
    });

    test('a zero catalog reward gets no event bonus', () {
      final preview = PurchaseRewardPreview(
        base: BigInt.zero,
        productBonus: BigInt.zero,
        multiplierTenths: 20,
      );

      expect(preview.eventBonus, BigInt.zero);
      expect(preview.expectedTotal, BigInt.zero);
    });

    test('negative catalog amounts are read as absent, never as a debt', () {
      final preview = PurchaseRewardPreview(
        base: big(-100),
        productBonus: big(-25),
        multiplierTenths: 20,
      );

      expect(preview.base, BigInt.zero);
      expect(preview.productBonus, BigInt.zero);
      expect(preview.eventBonus, BigInt.zero);
      expect(preview.expectedTotal, BigInt.zero);
    });

    test('arbitrary precision amounts stay exact', () {
      final huge = BigInt.parse('123456789012345678901234567890');
      final preview = PurchaseRewardPreview(
        base: huge,
        productBonus: BigInt.zero,
        multiplierTenths: 20,
      );

      expect(preview.eventBonus, huge);
      expect(preview.expectedTotal, huge * BigInt.two);
    });
  });

  group('catalog row reading', () {
    for (final amount in <double>[
      1.9,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      9007199254740992.0,
      1e30,
    ]) {
      for (final field in ['star_candy', 'star_candy_bonus']) {
        test('rejects malformed $field amount $amount without a bonus', () {
          final preview = purchaseRewardPreviewForProduct(
            {field: amount},
            multiplierTenths: 20,
            extraBonusBps: null,
          );

          expect(preview.base, BigInt.zero);
          expect(preview.productBonus, BigInt.zero);
          expect(preview.eventBonus, BigInt.zero);
          expect(preview.expectedTotal, BigInt.zero);
          expect(preview.totalMultiplierTenths, isNull);
        });
      }
    }

    test('finite exact whole doubles preserve the catalog reward', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'star_candy': 200.0, 'star_candy_bonus': 25.0},
        multiplierTenths: 20,
        extraBonusBps: null,
      );

      expect(preview.base, big(200));
      expect(preview.productBonus, big(25));
      expect(preview.eventBonus, big(225));
      expect(preview.expectedTotal, big(450));
    });

    test('large integer strings stay exact without double conversion', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'star_candy': '123456789012345678901234567890'},
        multiplierTenths: 20,
        extraBonusBps: null,
      );

      expect(preview.base, BigInt.parse('123456789012345678901234567890'));
      expect(
        preview.expectedTotal,
        BigInt.parse('246913578024691357802469135780'),
      );
    });

    test('reads star_candy and star_candy_bonus with the campaign', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'id': 'STAR200', 'star_candy': 200, 'star_candy_bonus': 25},
        multiplierTenths: 20,
        extraBonusBps: null,
      );

      expect(preview.base, big(200));
      expect(preview.productBonus, big(25));
      expect(preview.expectedTotal, big(450));
    });

    test('falls back to the legacy bonus_star_candy spelling', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'id': 'STAR200', 'star_candy': 200, 'bonus_star_candy': 25},
        multiplierTenths: null,
        extraBonusBps: null,
      );

      expect(preview.productBonus, big(25));
    });

    test('a non-numeric catalog amount reads as zero, not as a crash', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'id': 'STAR100', 'star_candy': 'one hundred'},
        multiplierTenths: 20,
        extraBonusBps: null,
      );

      expect(preview.base, BigInt.zero);
      expect(preview.eventBonus, BigInt.zero);
    });

    test('a missing catalog row reads as zero', () {
      final preview = purchaseRewardPreviewForProduct(
        const {'id': 'STAR100'},
        multiplierTenths: 20,
        extraBonusBps: null,
      );

      expect(preview.expectedTotal, BigInt.zero);
      expect(preview.hasEventBonus, isFalse);
    });
  });
}
