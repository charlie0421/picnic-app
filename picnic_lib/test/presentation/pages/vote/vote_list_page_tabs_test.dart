import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({'vote': []});
    // VoteList's loading skeleton overflows the headless test viewport
    // (pre-existing quirk, see vote_list_render_test.dart) — suppress like
    // the rest of the suite does instead of pumpAndSettle().
    restore = suppressImageErrors();
  });
  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  testWidgets('renders 4 vote-type tabs and defaults status to active', (tester) async {
    await tester.pumpWidget(buildTestApp(const VoteListContent(isAdmin: false)));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

    expect(find.text('PICNIC'), findsOneWidget);
    expect(find.text('PIC CHART'), findsOneWidget);
    expect(find.text('MUSICAL'), findsOneWidget);
    expect(find.text('SPOTLIGHT'), findsOneWidget);

    final active = AppLocalizations.of(tester.element(find.byType(VoteListContent)))
        .label_tabbar_vote_active;
    expect(find.text(active), findsWidgets); // 드롭다운 기본값
  });
}
