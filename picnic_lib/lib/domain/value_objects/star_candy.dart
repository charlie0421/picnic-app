class StarCandy {
  final int amount;

  const StarCandy(this.amount);

  /// Create StarCandy with validation
  factory StarCandy.create(int amount) {
    if (amount < 0) {
      throw NegativeStarCandyException('Star candy amount cannot be negative: $amount');
    }
    
    if (amount > maxAllowedAmount) {
      throw ExcessiveStarCandyException('Star candy amount exceeds maximum allowed: $amount');
    }
    
    return StarCandy(amount);
  }

  /// Zero star candy
  static const StarCandy zero = StarCandy(0);

  /// Maximum allowed star candy amount (prevent overflow and abuse)
  static const int maxAllowedAmount = 999999999; // ~1 billion

  /// Minimum purchase amount
  static const int minPurchaseAmount = 1;

  /// Common star candy amounts for purchases
  static const StarCandy smallAmount = StarCandy(100);
  static const StarCandy mediumAmount = StarCandy(500);
  static const StarCandy largeAmount = StarCandy(1000);

  /// Check if amount is positive
  bool get isPositive => amount > 0;

  /// Check if amount is zero
  bool get isZero => amount == 0;

  /// Check if amount is negative (shouldn't happen with validation)
  bool get isNegative => amount < 0;

  /// Check if this amount can afford another amount
  bool canAfford(StarCandy other) => amount >= other.amount;

  /// Check if amount is within valid range
  bool get isValid => amount >= 0 && amount <= maxAllowedAmount;

  /// Check if amount is sufficient for minimum purchase
  bool get isSufficientForPurchase => amount >= minPurchaseAmount;

  /// Add star candy (returns new instance)
  StarCandy operator +(StarCandy other) {
    final newAmount = amount + other.amount;
    if (newAmount > maxAllowedAmount) {
      throw ExcessiveStarCandyException('Sum exceeds maximum allowed: $newAmount');
    }
    return StarCandy(newAmount);
  }

  /// Subtract star candy (returns new instance)
  StarCandy operator -(StarCandy other) {
    final newAmount = amount - other.amount;
    if (newAmount < 0) {
      throw NegativeStarCandyException('Result would be negative: $newAmount');
    }
    return StarCandy(newAmount);
  }

  /// Multiply star candy by factor (returns new instance)
  StarCandy operator *(int factor) {
    if (factor < 0) {
      throw InvalidOperationException('Cannot multiply by negative factor: $factor');
    }
    
    final newAmount = amount * factor;
    if (newAmount > maxAllowedAmount) {
      throw ExcessiveStarCandyException('Product exceeds maximum allowed: $newAmount');
    }
    
    return StarCandy(newAmount);
  }

  /// Divide star candy by factor (returns new instance, integer division)
  StarCandy operator ~/(int factor) {
    if (factor <= 0) {
      throw InvalidOperationException('Cannot divide by zero or negative factor: $factor');
    }
    
    return StarCandy(amount ~/ factor);
  }

  /// Compare star candy amounts
  bool operator >(StarCandy other) => amount > other.amount;
  bool operator <(StarCandy other) => amount < other.amount;
  bool operator >=(StarCandy other) => amount >= other.amount;
  bool operator <=(StarCandy other) => amount <= other.amount;

  /// Get percentage of another amount
  double percentageOf(StarCandy total) {
    if (total.isZero) return 0.0;
    return (amount / total.amount) * 100;
  }

  /// Calculate bonus amount (e.g., 10% bonus)
  StarCandy calculateBonus(double percentage) {
    if (percentage < 0 || percentage > 100) {
      throw InvalidOperationException('Bonus percentage must be between 0 and 100: $percentage');
    }
    
    final bonusAmount = (amount * (percentage / 100)).round();
    return StarCandy(bonusAmount);
  }

  /// Format for display with proper thousand separators
  String get formatted {
    final str = amount.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(regex, (Match m) => '${m[1]},');
  }

  /// Format with star emoji for UI display
  String get displayText => '⭐ ${formatted}';

  /// Format with units (K for thousands, M for millions)
  String get compactFormat {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    }
    return amount.toString();
  }

  /// Convert to/from different representations
  Map<String, dynamic> toJson() => {'amount': amount};
  
  factory StarCandy.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as int;
    return StarCandy.create(amount);
  }

  /// Transaction history representation
  Map<String, dynamic> toTransactionData({
    required String type,
    required DateTime timestamp,
    String? description,
  }) {
    return {
      'amount': amount,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StarCandy && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'StarCandy($amount)';
}

// Domain Exceptions for StarCandy
class NegativeStarCandyException implements Exception {
  final String message;
  const NegativeStarCandyException(this.message);

  @override
  String toString() => 'NegativeStarCandyException: $message';
}

class ExcessiveStarCandyException implements Exception {
  final String message;
  const ExcessiveStarCandyException(this.message);

  @override
  String toString() => 'ExcessiveStarCandyException: $message';
}

class InvalidOperationException implements Exception {
  final String message;
  const InvalidOperationException(this.message);

  @override
  String toString() => 'InvalidOperationException: $message';
}