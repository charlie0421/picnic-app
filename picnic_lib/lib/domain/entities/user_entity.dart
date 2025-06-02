import 'package:picnic_lib/domain/value_objects/email.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';

class UserEntity {
  final String id;
  final String nickname;
  final Email email;
  final String? avatarUrl;
  final StarCandy starCandy;
  final StarCandy starCandyBonus;
  final bool isAdmin;
  final DateTime? birthDate;
  final String? gender;
  final String? birthTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final UserAgreement? userAgreement;

  const UserEntity({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
    required this.starCandy,
    required this.starCandyBonus,
    this.isAdmin = false,
    this.birthDate,
    this.gender,
    this.birthTime,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userAgreement,
  });

  // Business Logic Methods

  /// Check if user is active (not deleted)
  bool get isActive => deletedAt == null;

  /// Check if user profile is complete
  bool get isProfileComplete {
    return nickname.isNotEmpty &&
           email.isValid &&
           birthDate != null &&
           gender != null;
  }

  /// Check if user can perform admin actions
  bool get canPerformAdminActions => isAdmin && isActive;

  /// Check if user has agreed to terms
  bool get hasAgreedToTerms => userAgreement?.hasAgreedToTerms ?? false;

  /// Check if user has agreed to privacy policy
  bool get hasAgreedToPrivacy => userAgreement?.hasAgreedToPrivacy ?? false;

  /// Check if user can participate in votes
  bool get canParticipateInVotes {
    return isActive && isProfileComplete && hasAgreedToTerms;
  }

  /// Check if user can create content
  bool get canCreateContent {
    return isActive && hasAgreedToTerms && hasAgreedToPrivacy;
  }

  /// Check if user has sufficient star candy for a purchase
  bool canAfford(StarCandy amount) {
    return starCandy.amount >= amount.amount;
  }

  /// Calculate total available star candy (including bonus)
  StarCandy get totalStarCandy {
    return StarCandy(starCandy.amount + starCandyBonus.amount);
  }

  /// Check if user is eligible for bonus star candy
  bool get isEligibleForBonus {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return isActive && daysSinceCreation >= 1; // Can earn bonus after 1 day
  }

  /// Calculate user's age
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

  /// Check if user is adult (18+)
  bool get isAdult => age != null && age! >= 18;

  /// Check if user can access adult content
  bool get canAccessAdultContent => isAdult && isActive;

  /// Copy with method for immutability
  UserEntity copyWith({
    String? id,
    String? nickname,
    Email? email,
    String? avatarUrl,
    StarCandy? starCandy,
    StarCandy? starCandyBonus,
    bool? isAdmin,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    UserAgreement? userAgreement,
  }) {
    return UserEntity(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      starCandy: starCandy ?? this.starCandy,
      starCandyBonus: starCandyBonus ?? this.starCandyBonus,
      isAdmin: isAdmin ?? this.isAdmin,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      birthTime: birthTime ?? this.birthTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      userAgreement: userAgreement ?? this.userAgreement,
    );
  }

  /// Spend star candy (returns new user entity)
  UserEntity spendStarCandy(StarCandy amount) {
    if (!canAfford(amount)) {
      throw InsufficientStarCandyException(
        'Cannot afford ${amount.amount}. Current balance: ${starCandy.amount}'
      );
    }

    final newAmount = starCandy.amount - amount.amount;
    return copyWith(
      starCandy: StarCandy(newAmount),
      updatedAt: DateTime.now(),
    );
  }

  /// Add star candy (returns new user entity)
  UserEntity addStarCandy(StarCandy amount) {
    final newAmount = starCandy.amount + amount.amount;
    return copyWith(
      starCandy: StarCandy(newAmount),
      updatedAt: DateTime.now(),
    );
  }

  /// Add bonus star candy (returns new user entity)
  UserEntity addBonusStarCandy(StarCandy amount) {
    if (!isEligibleForBonus) {
      throw InvalidOperationException('User is not eligible for bonus star candy');
    }

    final newBonusAmount = starCandyBonus.amount + amount.amount;
    return copyWith(
      starCandyBonus: StarCandy(newBonusAmount),
      updatedAt: DateTime.now(),
    );
  }

  /// Update profile information
  UserEntity updateProfile({
    String? nickname,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) {
    // Validation
    if (nickname != null && nickname.length < 2) {
      throw ValidationException('Nickname must be at least 2 characters long');
    }

    if (nickname != null && nickname.length > 50) {
      throw ValidationException('Nickname must be less than 50 characters');
    }

    if (gender != null && !['male', 'female', 'other'].contains(gender.toLowerCase())) {
      throw ValidationException('Invalid gender value');
    }

    if (birthDate != null && birthDate.isAfter(DateTime.now())) {
      throw ValidationException('Birth date cannot be in the future');
    }

    return copyWith(
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      birthTime: birthTime ?? this.birthTime,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark user as deleted (soft delete)
  UserEntity markAsDeleted() {
    return copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Restore deleted user
  UserEntity restore() {
    return copyWith(
      deletedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserEntity(id: $id, nickname: $nickname, email: ${email.value})';
  }
}

class UserAgreement {
  final String userId;
  final DateTime? termsAgreedAt;
  final DateTime? privacyAgreedAt;

  const UserAgreement({
    required this.userId,
    this.termsAgreedAt,
    this.privacyAgreedAt,
  });

  bool get hasAgreedToTerms => termsAgreedAt != null;
  bool get hasAgreedToPrivacy => privacyAgreedAt != null;
  bool get hasAgreedToBoth => hasAgreedToTerms && hasAgreedToPrivacy;

  UserAgreement agreeToTerms() {
    return UserAgreement(
      userId: userId,
      termsAgreedAt: DateTime.now(),
      privacyAgreedAt: privacyAgreedAt,
    );
  }

  UserAgreement agreeToPrivacy() {
    return UserAgreement(
      userId: userId,
      termsAgreedAt: termsAgreedAt,
      privacyAgreedAt: DateTime.now(),
    );
  }

  UserAgreement agreeToBoth() {
    final now = DateTime.now();
    return UserAgreement(
      userId: userId,
      termsAgreedAt: now,
      privacyAgreedAt: now,
    );
  }
}

// Domain Exceptions
class InsufficientStarCandyException implements Exception {
  final String message;
  const InsufficientStarCandyException(this.message);

  @override
  String toString() => 'InsufficientStarCandyException: $message';
}

class InvalidOperationException implements Exception {
  final String message;
  const InvalidOperationException(this.message);

  @override
  String toString() => 'InvalidOperationException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}