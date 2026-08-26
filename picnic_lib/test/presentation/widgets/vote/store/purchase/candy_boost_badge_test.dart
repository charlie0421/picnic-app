import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  testWidgets(
    'renders the exact-double copy when bonusLabel is the exact-double string',
    (tester) async {
      initTestColors();
      await tester.pumpWidget(
        buildTestApp(
          const CandyBoostBadge(
            displayName: '캔디 부스트 데이',
            bonusLabel: '기본 지급 + 추가 보너스 100%',
          ),
        ),
      );
      expect(find.text('캔디 부스트 데이'), findsOneWidget);
      expect(find.text('기본 지급 + 추가 보너스 100%'), findsOneWidget);
    },
  );

  testWidgets('renders a V2 multiplier label verbatim', (tester) async {
    initTestColors();
    await tester.pumpWidget(
      buildTestApp(
        const CandyBoostBadge(displayName: '추석 캔디 부스트', bonusLabel: '1.5배'),
      ),
    );
    expect(find.text('추석 캔디 부스트'), findsOneWidget);
    expect(find.text('1.5배'), findsOneWidget);
  });

  test('formatCandyBoostMultiplierTenths drops a trailing .0 and never rounds', () {
    expect(formatCandyBoostMultiplierTenths(20), '2');
    expect(formatCandyBoostMultiplierTenths(15), '1.5');
    expect(formatCandyBoostMultiplierTenths(21), '2.1');
    expect(formatCandyBoostMultiplierTenths(11), '1.1');
  });
}
