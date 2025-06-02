part of 'artist_bloc.dart';

@freezed
class ArtistEvent with _$ArtistEvent {
  /// Load artist with optional requirements
  const factory ArtistEvent.loadArtist({
    required int artistId,
    @Default(true) bool requireActive,
    @Default(false) bool requireCompleteProfile,
  }) = ArtistLoadRequested;

  /// Vote for an artist
  const factory ArtistEvent.voteForArtist({
    required String userId,
    required int artistId,
    required int voteCount,
    @Default(false) bool useStarCandy,
    String? reason,
  }) = ArtistVoteRequested;

  /// Refresh artist data
  const factory ArtistEvent.refresh({
    required int artistId,
  }) = ArtistRefreshRequested;
}