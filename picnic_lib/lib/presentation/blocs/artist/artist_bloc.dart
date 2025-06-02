import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/domain/entities/artist_entity.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';
import 'package:picnic_lib/application/use_cases/artist/get_artist_use_case.dart';
import 'package:picnic_lib/application/use_cases/artist/vote_for_artist_use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';
import 'package:picnic_lib/core/utils/logger.dart';

part 'artist_event.dart';
part 'artist_state.dart';
part 'artist_bloc.freezed.dart';

class ArtistBloc extends Bloc<ArtistEvent, ArtistState> {
  final GetArtistUseCase _getArtistUseCase;
  final VoteForArtistUseCase _voteForArtistUseCase;

  ArtistBloc({
    required GetArtistUseCase getArtistUseCase,
    required VoteForArtistUseCase voteForArtistUseCase,
  })  : _getArtistUseCase = getArtistUseCase,
        _voteForArtistUseCase = voteForArtistUseCase,
        super(const ArtistState.initial()) {
    on<ArtistEvent>(
      (event, emit) async {
        await event.when(
          loadArtist: (artistId, requireActive, requireCompleteProfile) =>
              _onLoadArtist(emit, artistId, requireActive, requireCompleteProfile),
          voteForArtist: (userId, artistId, voteCount, useStarCandy, reason) =>
              _onVoteForArtist(emit, userId, artistId, voteCount, useStarCandy, reason),
          refresh: (artistId) => _onRefresh(emit, artistId),
        );
      },
    );
  }

  Future<void> _onLoadArtist(
    Emitter<ArtistState> emit,
    int artistId,
    bool requireActive,
    bool requireCompleteProfile,
  ) async {
    try {
      emit(const ArtistState.loading());

      final params = GetArtistParams(
        artistId: artistId,
        requireActive: requireActive,
        requireCompleteProfile: requireCompleteProfile,
      );

      final result = await _getArtistUseCase.execute(params);

      result.when(
        success: (artist) {
          if (artist != null) {
            emit(ArtistState.loaded(artist: artist));
          } else {
            emit(const ArtistState.error(message: 'Artist not found'));
          }
        },
        failure: (failure) {
          logger.e('Failed to load artist', error: failure.message);
          emit(ArtistState.error(message: failure.message));
        },
      );
    } catch (e) {
      logger.e('Unexpected error loading artist', error: e);
      emit(ArtistState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onVoteForArtist(
    Emitter<ArtistState> emit,
    String userId,
    int artistId,
    int voteCount,
    bool useStarCandy,
    String? reason,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ArtistLoaded) {
        emit(const ArtistState.error(message: 'No artist loaded'));
        return;
      }

      emit(ArtistState.voting(artist: currentState.artist));

      final params = VoteForArtistParams(
        userId: userId,
        artistId: artistId,
        voteCount: voteCount,
        useStarCandy: useStarCandy,
        reason: reason,
      );

      final result = await _voteForArtistUseCase.execute(params);

      result.when(
        success: (voteResult) {
          emit(ArtistState.loaded(
            artist: voteResult.artist,
            lastVoteResult: voteResult,
          ));
          logger.i('Vote successful: ${voteResult.summary}');
        },
        failure: (failure) {
          logger.e('Failed to vote for artist', error: failure.message);
          emit(ArtistState.error(
            message: failure.message,
            artist: currentState.artist,
          ));
        },
      );
    } catch (e) {
      logger.e('Unexpected error voting for artist', error: e);
      emit(ArtistState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onRefresh(
    Emitter<ArtistState> emit,
    int artistId,
  ) async {
    try {
      final params = GetArtistParams(artistId: artistId);
      final result = await _getArtistUseCase.execute(params);

      result.when(
        success: (artist) {
          if (artist != null) {
            emit(ArtistState.loaded(artist: artist));
          } else {
            emit(const ArtistState.error(message: 'Artist not found'));
          }
        },
        failure: (failure) {
          logger.e('Failed to refresh artist', error: failure.message);
          emit(ArtistState.error(message: failure.message));
        },
      );
    } catch (e) {
      logger.e('Unexpected error refreshing artist', error: e);
      emit(ArtistState.error(message: 'Unexpected error: $e'));
    }
  }
}