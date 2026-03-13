import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_privacy_page.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockAsyncPolicy extends AsyncPolicy {
  @override
  Future<PolicyModel> build() async {
    return const PolicyModel(
      privacyEn: PrivacyModel(content: '# Privacy Policy EN', version: '1.0'),
      termsEn: TermsModel(content: '# Terms EN', version: '1.0'),
      privacyKo: PrivacyModel(content: '# 개인정보처리방침', version: '1.0'),
      termsKo: TermsModel(content: '# 이용약관', version: '1.0'),
    );
  }
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'policy': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('AgreementPrivacyPage render', () {
    testWidgets('renders with mocked policy data', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const AgreementPrivacyPage(),
          extraOverrides: [
            asyncPolicyProvider.overrideWith(MockAsyncPolicy.new),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(AgreementPrivacyPage), findsOneWidget);
    });
  });
}
