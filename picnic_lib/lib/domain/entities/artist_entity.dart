import 'package:picnic_lib/domain/value_objects/content.dart';

class ArtistEntity {
  final int id;
  final Content name;
  final String? image;
  final DateTime? birthDate;
  final String? gender;
  final ArtistGroupEntity? artistGroup;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isBookmarked;
  final int totalVotes;
  final int currentRanking;

  const ArtistEntity({
    required this.id,
    required this.name,
    this.image,
    this.birthDate,
    this.gender,
    this.artistGroup,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isBookmarked = false,
    this.totalVotes = 0,
    this.currentRanking = 0,
  });

  // Business Logic Methods

  /// Check if artist is active (not deleted)
  bool get isActive => deletedAt == null;

  /// Check if artist is popular (more than 1000 votes)
  bool get isPopular => totalVotes >= 1000;

  /// Get artist popularity tier
  ArtistPopularityTier get popularityTier {
    if (totalVotes >= 10000) return ArtistPopularityTier.superstar;
    if (totalVotes >= 5000) return ArtistPopularityTier.star;
    if (totalVotes >= 1000) return ArtistPopularityTier.popular;
    if (totalVotes >= 100) return ArtistPopularityTier.rising;
    return ArtistPopularityTier.newbie;
  }

  /// Check if artist is in top rankings (top 100)
  bool get isInTopRankings => currentRanking > 0 && currentRanking <= 100;

  /// Check if artist can participate in votes
  bool get canParticipateInVotes => isActive;

  /// Check if artist can be featured
  bool get canBeFeatured => isActive && isPopular;

  /// Get formatted artist name for display
  String get displayName => name.value;

  /// Check if artist has complete profile
  bool get hasCompleteProfile {
    return name.isNotEmpty &&
           image != null &&
           birthDate != null &&
           gender != null;
  }

  /// Calculate artist's age
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Check if artist is part of a group
  bool get isInGroup => artistGroup != null;

  /// Check if artist is solo
  bool get isSolo => artistGroup == null;

  /// Get vote trend (requires historical data - placeholder logic)
  VoteTrend get voteTrend {
    // This would require historical vote data
    // For now, return based on current ranking
    if (currentRanking > 0 && currentRanking <= 10) return VoteTrend.rising;
    if (currentRanking > 10 && currentRanking <= 50) return VoteTrend.stable;
    return VoteTrend.declining;
  }

  /// Check if artist can receive votes
  bool canReceiveVotes() {
    return isActive && canParticipateInVotes;
  }

  /// Check if artist is eligible for special events
  bool isEligibleForEvents() {
    return isActive && hasCompleteProfile && totalVotes >= 50;
  }

  /// Copy with method for immutability
  ArtistEntity copyWith({
    int? id,
    Content? name,
    String? image,
    DateTime? birthDate,
    String? gender,
    ArtistGroupEntity? artistGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isBookmarked,
    int? totalVotes,
    int? currentRanking,
  }) {
    return ArtistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      artistGroup: artistGroup ?? this.artistGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      totalVotes: totalVotes ?? this.totalVotes,
      currentRanking: currentRanking ?? this.currentRanking,
    );
  }

  /// Add votes to artist
  ArtistEntity addVotes(int voteCount) {
    if (voteCount <= 0) {
      throw InvalidVoteCountException('Vote count must be positive');
    }

    return copyWith(
      totalVotes: totalVotes + voteCount,
      updatedAt: DateTime.now(),
    );
  }

  /// Update artist ranking
  ArtistEntity updateRanking(int newRanking) {
    if (newRanking < 0) {
      throw InvalidRankingException('Ranking cannot be negative');
    }

    return copyWith(
      currentRanking: newRanking,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle bookmark status
  ArtistEntity toggleBookmark() {
    return copyWith(
      isBookmarked: !isBookmarked,
      updatedAt: DateTime.now(),
    );
  }

  /// Update artist profile
  ArtistEntity updateProfile({
    Content? name,
    String? image,
    DateTime? birthDate,
    String? gender,
  }) {
    // Validation
    if (name != null && name.isEmpty) {
      throw ValidationException('Artist name cannot be empty');
    }

    if (gender != null && !['male', 'female', 'other'].contains(gender.toLowerCase())) {
      throw ValidationException('Invalid gender value');
    }

    if (birthDate != null && birthDate.isAfter(DateTime.now())) {
      throw ValidationException('Birth date cannot be in the future');
    }

    return copyWith(
      name: name ?? this.name,
      image: image ?? this.image,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark artist as deleted (soft delete)
  ArtistEntity markAsDeleted() {
    return copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Restore deleted artist
  ArtistEntity restore() {
    return copyWith(
      deletedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArtistEntity(id: $id, name: ${name.value}, totalVotes: $totalVotes)';
  }
}

class ArtistGroupEntity {
  final int id;
  final Content name;
  final String? image;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ArtistGroupEntity({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Check if group is active
  bool get isActive => deletedAt == null;

  /// Get display name
  String get displayName => name.value;

  /// Copy with method
  ArtistGroupEntity copyWith({
    int? id,
    Content? name,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ArtistGroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistGroupEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArtistGroupEntity(id: $id, name: ${name.value})';
  }
}

// Enums for Artist domain

enum ArtistPopularityTier {
  newbie,
  rising,
  popular,
  star,
  superstar,
}

enum VoteTrend {
  rising,
  stable,
  declining,
}

// Domain Exceptions for Artist

class InvalidVoteCountException implements Exception {
  final String message;
  const InvalidVoteCountException(this.message);

  @override
  String toString() => 'InvalidVoteCountException: $message';
}

class InvalidRankingException implements Exception {
  final String message;
  const InvalidRankingException(this.message);

  @override
  String toString() => 'InvalidRankingException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}