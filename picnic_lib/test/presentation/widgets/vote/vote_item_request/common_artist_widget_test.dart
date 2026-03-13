import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/common_artist_widget.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommonArtistWidget', () {
    testWidgets('renders with null artist', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonArtistWidget(
            artist: null,
            artistName: 'Test Artist',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommonArtistWidget), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with empty artist name shows fallback', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonArtistWidget(
            artist: null,
            artistName: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommonArtistWidget), findsOneWidget);
      expect(find.text('알 수 없는 아티스트'), findsOneWidget);
    });

    testWidgets('renders with group name', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonArtistWidget(
            artist: null,
            artistName: 'V',
            groupName: 'BTS',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('V'), findsOneWidget);
      expect(find.text('BTS'), findsOneWidget);
    });

    testWidgets('renders with trailing widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonArtistWidget(
            artist: null,
            artistName: 'Artist',
            trailing: Icon(Icons.check),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
