import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeViewState {
  const HomeViewState({
    this.scrollOffset = 0,
    this.selectedVoteId,
    this.contentScope,
  });

  final double scrollOffset;
  final int? selectedVoteId;
  final String? contentScope;

  HomeViewState copyWith({
    double? scrollOffset,
    Object? selectedVoteId = _notProvided,
    String? contentScope,
  }) {
    return HomeViewState(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      selectedVoteId: identical(selectedVoteId, _notProvided)
          ? this.selectedVoteId
          : selectedVoteId as int?,
      contentScope: contentScope ?? this.contentScope,
    );
  }
}

const Object _notProvided = Object();

class HomeViewStateNotifier extends Notifier<HomeViewState> {
  @override
  HomeViewState build() => const HomeViewState();

  void saveScrollOffset(double offset) {
    if (offset.isNegative || !offset.isFinite) return;
    state = state.copyWith(scrollOffset: offset);
  }

  void selectVote(int? voteId) {
    state = state.copyWith(selectedVoteId: voteId);
  }

  void setContentScope(String scope) {
    if (state.contentScope == scope) return;
    state = HomeViewState(contentScope: scope);
  }
}

final homeViewStateProvider =
    NotifierProvider<HomeViewStateNotifier, HomeViewState>(
      HomeViewStateNotifier.new,
    );
