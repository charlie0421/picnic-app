import 'package:picnic_lib/data/models/admin/payment_breakdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  const AdminRepository(this.client);

  final SupabaseClient client;

  Future<List<PaymentBreakdownItem>> getPaymentBreakdown({
    required PaymentBreakdownDimension dimension,
  }) async {
    final value = await client.rpc(
      'get_payment_breakdown',
      params: {
        'p_start': null,
        'p_end': null,
        'p_dimension': dimension.wireValue,
      },
    );
    if (value is! List) {
      throw const FormatException('Payment breakdown response must be a list');
    }

    return value
        .map((item) {
          if (item is! Map) {
            throw const FormatException(
              'Payment breakdown row must be an object',
            );
          }
          return PaymentBreakdownItem.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }
}
