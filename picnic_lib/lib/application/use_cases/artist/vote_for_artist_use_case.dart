import 'package:picnic_lib/domain/entities/artist_entity.dart';
import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/interfaces/artist_repository_interface.dart';
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';
import 'package:picnic_lib/application/common/use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';

class VoteForArtistUseCase implements UseCase<VoteForArtistParams, VoteResult> {
  final IArtistRepository _artistRepository;
  final IUserRepository _userRepository;

  const VoteForArtistUseCase(this._artistRepository, this._userRepository);

  @override
  Future<UseCaseResult<VoteResult>> execute(VoteForArtistParams params) async {
    try {
      // Validate input parameters
      if (params.userId.isEmpty) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('User ID cannot be empty')
        );
      }

      if (params.artistId <= 0) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('Artist ID must be positive')
        );
      }

      if (params.voteCount <= 0) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('Vote count must be positive')
        );
      }

      // Get user and validate
      final user = await _userRepository.getUserById(params.userId);
      if (user == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('User not found')
        );
      }

      if (!user.isActive) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User account is deactivated')
        );
      }

      if (!user.canParticipateInVotes) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User cannot participate in votes')
        );
      }

      // Get artist and validate
      final artist = await _artistRepository.getArtistById(params.artistId);
      if (artist == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('Artist not found')
        );
      }

      if (!artist.canReceiveVotes()) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Artist cannot receive votes')
        );
      }

      // Check vote limits
      final voteLimitValidation = await _validateVoteLimits(user, params.voteCount);
      if (voteLimitValidation.isFailure) {
        return voteLimitValidation;
      }

      // Calculate star candy cost if voting with star candy
      StarCandy? starCandyCost;
      if (params.useStarCandy) {
        starCandyCost = _calculateStarCandyCost(params.voteCount);
        
        if (!user.canAfford(starCandyCost)) {
          return UseCaseResult.failure(
            UseCaseFailure.businessRule(
              'Insufficient star candy. Required: ${starCandyCost.amount}, Available: ${user.starCandy.amount}'
            )
          );
        }
      }

      // Check daily vote limit for user
      final todayVotes = await _artistRepository.getUserDailyVoteCount(params.userId);
      final maxDailyVotes = params.useStarCandy ? 100 : 10; // Higher limit with star candy
      
      if (todayVotes + params.voteCount > maxDailyVotes) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule(
            'Daily vote limit exceeded. You can vote ${maxDailyVotes - todayVotes} more times today'
          )
        );
      }

      // Execute vote transaction
      final voteResult = await _executeVote(user, artist, params, starCandyCost);
      return voteResult;

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to vote for artist: $e')
      );
    }
  }

  Future<UseCaseResult<VoteResult>> _executeVote(
    UserEntity user,
    ArtistEntity artist,
    VoteForArtistParams params,
    StarCandy? starCandyCost,
  ) async {
    try {
      // Start transaction
      UserEntity updatedUser = user;
      
      // Deduct star candy if required
      if (starCandyCost != null) {
        updatedUser = await _userRepository.spendStarCandy(
          userId: params.userId,
          amount: starCandyCost,
          reason: 'Vote for ${artist.displayName}',
        );
      }

      // Record the vote
      final voteRecord = await _artistRepository.addVote(
        userId: params.userId,
        artistId: params.artistId,
        voteCount: params.voteCount,
        starCandyUsed: starCandyCost?.amount ?? 0,
      );

      // Get updated artist with new vote count
      final updatedArtist = await _artistRepository.getArtistById(params.artistId);

      return UseCaseResult.success(
        VoteResult(
          user: updatedUser,
          artist: updatedArtist!,
          voteCount: params.voteCount,
          starCandyUsed: starCandyCost,
          voteRecord: voteRecord,
          timestamp: DateTime.now(),
        )
      );

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to execute vote: $e')
      );
    }
  }

  Future<UseCaseResult<VoteResult>> _validateVoteLimits(UserEntity user, int voteCount) async {
    // Check maximum votes per transaction
    const maxVotesPerTransaction = 50;
    if (voteCount > maxVotesPerTransaction) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Maximum $maxVotesPerTransaction votes per transaction'
        )
      );
    }

    return UseCaseResult.success(VoteResult(
      user: user,
      artist: ArtistEntity(id: 0, name: Content.unsafe('', ContentType.title), createdAt: DateTime.now()),
      voteCount: 0,
      starCandyUsed: null,
      voteRecord: VoteRecord(id: 0, userId: '', artistId: 0, voteCount: 0, timestamp: DateTime.now()),
      timestamp: DateTime.now(),
    ));
  }

  StarCandy _calculateStarCandyCost(int voteCount) {
    // 1 star candy per vote (can be adjusted based on business rules)
    const starCandyPerVote = 1;
    return StarCandy(voteCount * starCandyPerVote);
  }
}

class VoteForArtistParams {
  final String userId;
  final int artistId;
  final int voteCount;
  final bool useStarCandy;
  final String? reason;

  const VoteForArtistParams({
    required this.userId,
    required this.artistId,
    required this.voteCount,
    this.useStarCandy = false,
    this.reason,
  });

  @override
  String toString() {
    return 'VoteForArtistParams(userId: $userId, artistId: $artistId, voteCount: $voteCount, useStarCandy: $useStarCandy)';
  }
}

class VoteResult {
  final UserEntity user;
  final ArtistEntity artist;
  final int voteCount;
  final StarCandy? starCandyUsed;
  final VoteRecord voteRecord;
  final DateTime timestamp;

  const VoteResult({
    required this.user,
    required this.artist,
    required this.voteCount,
    this.starCandyUsed,
    required this.voteRecord,
    required this.timestamp,
  });

  /// Check if star candy was used
  bool get usedStarCandy => starCandyUsed != null;

  /// Get vote efficiency (votes per star candy)
  double get voteEfficiency {
    if (starCandyUsed == null || starCandyUsed!.isZero) return double.infinity;
    return voteCount / starCandyUsed!.amount;
  }

  /// Get vote summary for display
  String get summary {
    final starCandyText = usedStarCandy ? ' (${starCandyUsed!.displayText} spent)' : '';
    return 'Voted $voteCount times for ${artist.displayName}$starCandyText';
  }

  @override
  String toString() {
    return 'VoteResult(voteCount: $voteCount, artist: ${artist.displayName}, starCandyUsed: $starCandyUsed)';
  }
}

class VoteRecord {
  final int id;
  final String userId;
  final int artistId;
  final int voteCount;
  final int starCandyUsed;
  final DateTime timestamp;

  const VoteRecord({
    required this.id,
    required this.userId,
    required this.artistId,
    required this.voteCount,
    this.starCandyUsed = 0,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'VoteRecord(id: $id, userId: $userId, artistId: $artistId, voteCount: $voteCount)';
  }
}