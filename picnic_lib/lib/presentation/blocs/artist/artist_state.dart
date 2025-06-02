part of 'artist_bloc.dart';

@freezed
class ArtistState with _$ArtistState {
  /// Initial state when no operation has been performed
  const factory ArtistState.initial() = ArtistInitial;

  /// Loading state during asynchronous operations
  const factory ArtistState.loading({
    ArtistEntity? artist, // Keep previous artist data during updates
  }) = ArtistLoading;

  /// Voting state during vote operation
  const factory ArtistState.voting({
    required ArtistEntity artist,
  }) = ArtistVoting;

  /// Successfully loaded artist
  const factory ArtistState.loaded({
    required ArtistEntity artist,
    VoteResult? lastVoteResult, // Result of last vote if any
  }) = ArtistLoaded;

  /// Error state with error message
  const factory ArtistState.error({
    required String message,
    ArtistEntity? artist, // Keep previous artist data if available
  }) = ArtistError;
}

/// Extension for convenient state checking
extension ArtistStateX on ArtistState {
  /// Check if the state is loading
  bool get isLoading => this is ArtistLoading;

  /// Check if the state is voting
  bool get isVoting => this is ArtistVoting;

  /// Check if the state has loaded data
  bool get isLoaded => this is ArtistLoaded;

  /// Check if the state has an error
  bool get hasError => this is ArtistError;

  /// Get the artist entity if available
  ArtistEntity? get artist => when(
    initial: () => null,
    loading: (artist) => artist,
    voting: (artist) => artist,
    loaded: (artist, _) => artist,
    error: (message, artist) => artist,
  );

  /// Get the error message if in error state
  String? get errorMessage => when(
    initial: () => null,
    loading: (_) => null,
    voting: (_) => null,
    loaded: (_, __) => null,
    error: (message, _) => message,
  );

  /// Get the last vote result if available
  VoteResult? get lastVoteResult => when(
    initial: () => null,
    loading: (_) => null,
    voting: (_) => null,
    loaded: (_, lastVoteResult) => lastVoteResult,
    error: (_, __) => null,
  );

  /// Check if user can perform actions (not in loading or voting state)
  bool get canPerformActions => !isLoading && !isVoting;

  /// Check if artist can receive votes
  bool get canReceiveVotes => artist?.canReceiveVotes() ?? false;

  /// Check if artist is popular
  bool get isPopular => artist?.isPopular ?? false;

  /// Check if artist is in top rankings
  bool get isInTopRankings => artist?.isInTopRankings ?? false;

  /// Get artist popularity tier
  ArtistPopularityTier get popularityTier => 
      artist?.popularityTier ?? ArtistPopularityTier.newbie;

  /// Get artist vote trend
  VoteTrend get voteTrend => artist?.voteTrend ?? VoteTrend.stable;

  /// Get total votes count
  int get totalVotes => artist?.totalVotes ?? 0;

  /// Get current ranking
  int get currentRanking => artist?.currentRanking ?? 0;

  /// Check if artist is bookmarked
  bool get isBookmarked => artist?.isBookmarked ?? false;

  /// Get display name
  String get displayName => artist?.displayName ?? 'Unknown Artist';
}