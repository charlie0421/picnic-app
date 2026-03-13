import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  Widget buildWidget({
    bool shouldShowApplicationButton = false,
    bool isSubmitting = false,
    bool isAlreadyInVote = false,
    String status = '신청 가능',
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return buildTestApp(
      SearchResultActionButton(
        shouldShowApplicationButton: shouldShowApplicationButton,
        isSubmitting: isSubmitting,
        isAlreadyInVote: isAlreadyInVote,
        status: status,
        onPressed: onPressed ?? () {},
        isLoading: isLoading,
      ),
    );
  }

  group('SearchResultActionButton', () {
    testWidgets('shows CircularProgressIndicator when isLoading=true',
        (tester) async {
      await tester.pumpWidget(buildWidget(isLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows submit button when shouldShowApplicationButton=true',
        (tester) async {
      await tester.pumpWidget(
          buildWidget(shouldShowApplicationButton: true));
      await tester.pump();
      // Clear Image.asset error from PulseLoadingIndicator
      tester.takeException();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('신청'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('button is disabled when isSubmitting=true', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildWidget(
        shouldShowApplicationButton: true,
        isSubmitting: true,
        onPressed: () => pressed = true,
      ));
      await tester.pump();
      // Clear Image.asset error from PulseLoadingIndicator
      tester.takeException();

      final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isFalse);
    });

    testWidgets('shows check icon when isAlreadyInVote=true', (tester) async {
      await tester.pumpWidget(buildWidget(isAlreadyInVote: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows status text for waiting status', (tester) async {
      await tester.pumpWidget(buildWidget(status: '대기 중'));
      await tester.pumpAndSettle();

      expect(find.text('대기 중'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('shows status text for approved status', (tester) async {
      await tester.pumpWidget(buildWidget(status: '승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('승인됨'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows status text for pending status', (tester) async {
      await tester.pumpWidget(buildWidget(status: '대기중'));
      await tester.pumpAndSettle();

      expect(find.text('대기중'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink as default fallback', (tester) async {
      // status == '신청 가능' (can_apply) and all flags false => SizedBox.shrink
      await tester.pumpWidget(buildWidget(status: '신청 가능'));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('onPressed callback fires when button tapped',
        (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildWidget(
        shouldShowApplicationButton: true,
        onPressed: () => pressed = true,
      ));
      await tester.pump();
      // Clear Image.asset error from PulseLoadingIndicator
      tester.takeException();

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });
  });
}
