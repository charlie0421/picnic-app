import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/home_view_state_provider.dart';

void main() {
  test('home view state keeps offset and selected stable vote id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(homeViewStateProvider.notifier)
      ..saveScrollOffset(320)
      ..selectVote(42);

    expect(container.read(homeViewStateProvider).scrollOffset, 320);
    expect(container.read(homeViewStateProvider).selectedVoteId, 42);
  });

  test('changing content scope resets saved home state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(homeViewStateProvider.notifier)
      ..setContentScope('ko')
      ..saveScrollOffset(200)
      ..selectVote(7);

    notifier.setContentScope('en');

    expect(container.read(homeViewStateProvider).scrollOffset, 0);
    expect(container.read(homeViewStateProvider).selectedVoteId, isNull);
  });
}
