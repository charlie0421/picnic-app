import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _EmptyBookmarkedArtists extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => const [];
}

void main() {
  setUp(() async {
    initTestColors();
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth({
      'artist_user_bookmark': <Map<String, dynamic>>[],
      'user_notifications': <Map<String, dynamic>>[],
      'broadcast_notifications': <Map<String, dynamic>>[],
    }, userId: 'test-user-id');
  });

  tearDown(tearDownMockSupabase);

  testWidgets('MyPage notification entry requests the embedded mode', (
    tester,
  ) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        const MyPageScreen(),
        navigation: Navigation.initial(),
        userProfile: MockData.userProfile(id: 'test-user-id'),
        extraOverrides: [
          asyncBookmarkedArtistsProvider.overrideWith(
            _EmptyBookmarkedArtists.new,
          ),
        ],
      ),
    );
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

    final entry = find.text('알림함');
    await tester.scrollUntilVisible(
      entry,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 600));

    expect(find.byType(NotificationsPage), findsOneWidget);
    final page = tester.widget<NotificationsPage>(
      find.byType(NotificationsPage),
    );
    expect(page.mode, NotificationsPageMode.embedded);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('알림함'), findsOneWidget);
  });
}
