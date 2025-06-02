import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';
import 'package:picnic_lib/application/common/use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';

class ManageStarCandyUseCase implements UseCase<ManageStarCandyParams, StarCandyTransactionResult> {
  final IUserRepository _userRepository;

  const ManageStarCandyUseCase(this._userRepository);

  @override
  Future<UseCaseResult<StarCandyTransactionResult>> execute(ManageStarCandyParams params) async {
    try {
      // Validate input parameters
      if (params.userId.isEmpty) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('User ID cannot be empty')
        );
      }

      if (params.amount.amount <= 0) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('Amount must be positive')
        );
      }

      if (params.reason.trim().isEmpty) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('Transaction reason is required')
        );
      }

      // Get current user
      final currentUser = await _userRepository.getUserById(params.userId);
      if (currentUser == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('User not found with ID: ${params.userId}')
        );
      }

      // Check if user is active
      if (!currentUser.isActive) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Cannot manage star candy for deactivated user')
        );
      }

      // Execute transaction based on type
      final result = await _executeTransaction(currentUser, params);
      return result;

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to manage star candy: $e')
      );
    }
  }

  Future<UseCaseResult<StarCandyTransactionResult>> _executeTransaction(
    UserEntity user, 
    ManageStarCandyParams params
  ) async {
    switch (params.transactionType) {
      case StarCandyTransactionType.add:
        return await _addStarCandy(user, params);
      
      case StarCandyTransactionType.spend:
        return await _spendStarCandy(user, params);
      
      case StarCandyTransactionType.addBonus:
        return await _addBonusStarCandy(user, params);
    }
  }

  Future<UseCaseResult<StarCandyTransactionResult>> _addStarCandy(
    UserEntity user, 
    ManageStarCandyParams params
  ) async {
    // Validate daily add limits
    final dailyLimitValidation = _validateDailyAddLimit(params.amount);
    if (dailyLimitValidation.isFailure) {
      return UseCaseResult.failure(dailyLimitValidation.failure!);
    }

    // Check maximum balance limit
    final maxBalanceValidation = _validateMaxBalance(user, params.amount);
    if (maxBalanceValidation.isFailure) {
      return UseCaseResult.failure(maxBalanceValidation.failure!);
    }

    // Add star candy
    final updatedUser = await _userRepository.addStarCandy(
      userId: params.userId,
      amount: params.amount,
      reason: params.reason,
    );

    return UseCaseResult.success(
      StarCandyTransactionResult(
        user: updatedUser,
        transactionType: params.transactionType,
        amount: params.amount,
        previousBalance: user.starCandy,
        newBalance: updatedUser.starCandy,
        reason: params.reason,
        timestamp: DateTime.now(),
      )
    );
  }

  Future<UseCaseResult<StarCandyTransactionResult>> _spendStarCandy(
    UserEntity user, 
    ManageStarCandyParams params
  ) async {
    // Check if user has sufficient balance
    if (!user.canAfford(params.amount)) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Insufficient star candy. Required: ${params.amount.amount}, Available: ${user.starCandy.amount}'
        )
      );
    }

    // Validate minimum spend amount
    if (params.amount.amount < StarCandy.minPurchaseAmount) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Minimum spend amount is ${StarCandy.minPurchaseAmount} star candy'
        )
      );
    }

    // Check spending limits (daily/monthly)
    final spendingLimitValidation = _validateSpendingLimits(params.amount);
    if (spendingLimitValidation.isFailure) {
      return UseCaseResult.failure(spendingLimitValidation.failure!);
    }

    // Spend star candy
    final updatedUser = await _userRepository.spendStarCandy(
      userId: params.userId,
      amount: params.amount,
      reason: params.reason,
    );

    return UseCaseResult.success(
      StarCandyTransactionResult(
        user: updatedUser,
        transactionType: params.transactionType,
        amount: params.amount,
        previousBalance: user.starCandy,
        newBalance: updatedUser.starCandy,
        reason: params.reason,
        timestamp: DateTime.now(),
      )
    );
  }

  Future<UseCaseResult<StarCandyTransactionResult>> _addBonusStarCandy(
    UserEntity user, 
    ManageStarCandyParams params
  ) async {
    // Check if user is eligible for bonus
    if (!user.isEligibleForBonus) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule('User is not eligible for bonus star candy')
      );
    }

    // Validate bonus amount limits
    final bonusLimitValidation = _validateBonusLimits(params.amount);
    if (bonusLimitValidation.isFailure) {
      return UseCaseResult.failure(bonusLimitValidation.failure!);
    }

    // Add bonus star candy
    final updatedUser = await _userRepository.addBonusStarCandy(
      userId: params.userId,
      amount: params.amount,
      reason: params.reason,
    );

    return UseCaseResult.success(
      StarCandyTransactionResult(
        user: updatedUser,
        transactionType: params.transactionType,
        amount: params.amount,
        previousBalance: user.starCandyBonus,
        newBalance: updatedUser.starCandyBonus,
        reason: params.reason,
        timestamp: DateTime.now(),
      )
    );
  }

  UseCaseResult<void> _validateDailyAddLimit(StarCandy amount) {
    const dailyAddLimit = 10000; // Example daily limit
    
    if (amount.amount > dailyAddLimit) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Daily add limit exceeded. Maximum: $dailyAddLimit star candy'
        )
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateMaxBalance(UserEntity user, StarCandy amount) {
    final newBalance = user.starCandy.amount + amount.amount;
    
    if (newBalance > StarCandy.maxAllowedAmount) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Maximum balance limit would be exceeded. Current: ${user.starCandy.amount}, Adding: ${amount.amount}, Limit: ${StarCandy.maxAllowedAmount}'
        )
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateSpendingLimits(StarCandy amount) {
    const dailySpendLimit = 5000; // Example daily spending limit
    
    if (amount.amount > dailySpendLimit) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Daily spending limit exceeded. Maximum: $dailySpendLimit star candy'
        )
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateBonusLimits(StarCandy amount) {
    const maxBonusAmount = 1000; // Example maximum bonus amount
    
    if (amount.amount > maxBonusAmount) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule(
          'Bonus amount exceeds maximum limit. Maximum: $maxBonusAmount star candy'
        )
      );
    }

    return UseCaseResult.success(null);
  }
}

class ManageStarCandyParams {
  final String userId;
  final StarCandy amount;
  final StarCandyTransactionType transactionType;
  final String reason;

  const ManageStarCandyParams({
    required this.userId,
    required this.amount,
    required this.transactionType,
    required this.reason,
  });

  @override
  String toString() {
    return 'ManageStarCandyParams(userId: $userId, amount: $amount, type: $transactionType, reason: $reason)';
  }
}

enum StarCandyTransactionType {
  add,
  spend,
  addBonus,
}

class StarCandyTransactionResult {
  final UserEntity user;
  final StarCandyTransactionType transactionType;
  final StarCandy amount;
  final StarCandy previousBalance;
  final StarCandy newBalance;
  final String reason;
  final DateTime timestamp;

  const StarCandyTransactionResult({
    required this.user,
    required this.transactionType,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.reason,
    required this.timestamp,
  });

  /// Calculate the balance change
  StarCandy get balanceChange {
    switch (transactionType) {
      case StarCandyTransactionType.add:
      case StarCandyTransactionType.addBonus:
        return amount;
      case StarCandyTransactionType.spend:
        return StarCandy(-amount.amount);
    }
  }

  /// Check if transaction was successful
  bool get isSuccessful => newBalance != previousBalance;

  /// Get transaction summary for display
  String get summary {
    final operation = switch (transactionType) {
      StarCandyTransactionType.add => 'Added',
      StarCandyTransactionType.spend => 'Spent',
      StarCandyTransactionType.addBonus => 'Bonus Added',
    };
    
    return '$operation ${amount.displayText} - $reason';
  }

  @override
  String toString() {
    return 'StarCandyTransactionResult(type: $transactionType, amount: $amount, previousBalance: $previousBalance, newBalance: $newBalance)';
  }
}