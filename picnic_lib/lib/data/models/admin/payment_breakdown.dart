import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

enum PaymentBreakdownDimension { platform, product }

extension PaymentBreakdownDimensionWire on PaymentBreakdownDimension {
  String get wireValue => switch (this) {
    PaymentBreakdownDimension.platform => 'platform',
    PaymentBreakdownDimension.product => 'product',
  };
}

class PaymentBreakdownItem {
  const PaymentBreakdownItem({
    required this.key,
    required this.payCount,
    required this.revenueUsd,
  });

  final String key;
  final BigInt payCount;

  /// Decimal text normalized from the reporting RPC.
  ///
  /// Keeping the display value as text prevents additional binary
  /// floating-point conversions in the presentation layer.
  final String revenueUsd;

  factory PaymentBreakdownItem.fromJson(Map<String, dynamic> json) {
    final exact = requireExactContractKeys(json, {
      'key',
      'pay_cnt',
      'revenue_usd',
    });
    final key = exact['key'];
    final payCount = exact['pay_cnt'];
    final revenueUsd = exact['revenue_usd'];

    if (key is! String || key.isEmpty) {
      throw const FormatException('Payment breakdown key must be a string');
    }
    return PaymentBreakdownItem(
      key: key,
      payCount: _parsePayCount(payCount),
      revenueUsd: _normalizeRevenueUsd(revenueUsd),
    );
  }

  static BigInt _parsePayCount(Object? value) {
    if (value is String && RegExp(r'^[0-9]+$').hasMatch(value)) {
      return BigInt.parse(value);
    }
    if (value is int && value >= 0) return BigInt.from(value);
    if (value is double &&
        value.isFinite &&
        value >= 0 &&
        value == value.truncateToDouble() &&
        value <= 9007199254740991) {
      return BigInt.from(value.toInt());
    }
    throw const FormatException(
      'Payment breakdown pay_cnt must be a non-negative integer',
    );
  }

  static String _normalizeRevenueUsd(Object? value) {
    final decimal = switch (value) {
      String value => value,
      int value => value.toString(),
      double value when value.isFinite => _expandExponent(value.toString()),
      _ => throw const FormatException(
        'Payment breakdown revenue_usd must be a finite decimal',
      ),
    };
    if (!RegExp(r'^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(decimal)) {
      throw const FormatException(
        'Payment breakdown revenue_usd must be a finite decimal',
      );
    }
    return decimal;
  }

  static String _expandExponent(String value) {
    final parts = value.split(RegExp('[eE]'));
    if (parts.length == 1) return value;

    final mantissa = parts[0];
    final exponent = int.parse(parts[1]);
    final negative = mantissa.startsWith('-');
    final unsigned = negative ? mantissa.substring(1) : mantissa;
    final decimalOffset = unsigned.indexOf('.');
    final integerLength = decimalOffset == -1 ? unsigned.length : decimalOffset;
    final digits = unsigned.replaceAll('.', '');
    final point = integerLength + exponent;
    final normalized = point <= 0
        ? '0.${'0' * -point}$digits'
        : point >= digits.length
        ? '$digits${'0' * (point - digits.length)}'
        : '${digits.substring(0, point)}.${digits.substring(point)}';
    return negative ? '-$normalized' : normalized;
  }
}
