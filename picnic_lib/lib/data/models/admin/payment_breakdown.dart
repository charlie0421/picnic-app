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

  /// Exact decimal text from the reporting RPC.
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
      revenueUsd: _parseRevenueUsd(revenueUsd),
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

  static String _parseRevenueUsd(Object? value) {
    if (value is! String ||
        !RegExp(r'^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(value)) {
      throw const FormatException(
        'Payment breakdown revenue_usd must be a decimal string',
      );
    }
    return value;
  }
}
