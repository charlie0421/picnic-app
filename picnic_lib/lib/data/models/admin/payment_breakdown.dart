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

  /// Decimal text as returned by the reporting RPC.
  ///
  /// Keeping this as text prevents a JSON number from being widened through
  /// `double` before it reaches a financial/admin surface.
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
    if (payCount is! String || !RegExp(r'^[0-9]+$').hasMatch(payCount)) {
      throw const FormatException(
        'Payment breakdown pay_cnt must be a decimal string',
      );
    }
    if (revenueUsd is! String ||
        !RegExp(r'^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$').hasMatch(revenueUsd)) {
      throw const FormatException(
        'Payment breakdown revenue_usd must be a decimal string',
      );
    }

    return PaymentBreakdownItem(
      key: key,
      payCount: BigInt.parse(payCount),
      revenueUsd: revenueUsd,
    );
  }
}
