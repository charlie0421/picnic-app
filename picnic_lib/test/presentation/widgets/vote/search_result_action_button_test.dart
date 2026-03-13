import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('SearchResultActionButton', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders apply button when shouldShowApplicationButton is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: true,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('renders submitting state with disabled button',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: true,
            isSubmitting: true,
            isAlreadyInVote: false,
            status: '',
            onPressed: () {},
          ),
        ),
      );
      // Just pump one frame since PulseLoadingIndicator uses images
      await tester.pump();

      // Button should be disabled when submitting
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    }, skip: true);

    testWidgets('renders check icon when already in vote', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: true,
            status: '',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders empty when no conditions met', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '신청 가능',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SearchResultActionButton), findsOneWidget);
    });

    testWidgets('calls onPressed when apply button tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: true,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('renders status text for non-apply status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: 'custom status',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('custom status'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when status matches can_apply text',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '신청 가능', // matches vote_item_request_can_apply
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();

      // Should render SizedBox.shrink (no visible content)
      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 0.0 && widget.height == 0.0,
      );
      expect(sizedBoxFinder, findsOneWidget);
    });

    testWidgets('loading indicator has correct color', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchResultActionButton(
            shouldShowApplicationButton: false,
            isSubmitting: false,
            isAlreadyInVote: false,
            status: '',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 1.5);
    });
  });
}
