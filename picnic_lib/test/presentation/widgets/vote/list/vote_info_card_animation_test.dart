import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  testWidgets('prepared card content is visible on its first frame', (
    tester,
  ) async {
    final vote = VoteFactory.create(
      voteItem: [VoteItemFactory.create(id: 1), VoteItemFactory.create(id: 2)],
    );

    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) => VoteInfoCard(
            context: context,
            vote: vote,
            status: VoteStatus.active,
          ),
        ),
      ),
    );

    final card = find.byType(VoteInfoCard);
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(of: card, matching: find.byType(FadeTransition)),
    );
    final slides = tester.widgetList<SlideTransition>(
      find.descendant(of: card, matching: find.byType(SlideTransition)),
    );

    expect(fades, isNotEmpty);
    expect(fades.every((fade) => fade.opacity.value == 1), isTrue);
    expect(slides, isNotEmpty);
    expect(slides.every((slide) => slide.position.value.dy <= 0.05), isTrue);

    await tester.pump(const Duration(milliseconds: 180));
    expect(
      slides.every((slide) => slide.position.value == Offset.zero),
      isTrue,
    );
  });
}
