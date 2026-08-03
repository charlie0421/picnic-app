import 'package:picnic_lib/data/models/admin/payment_breakdown.dart';
import 'package:picnic_lib/data/repositories/admin_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/admin_provider.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) => AdminRepository(supabase);

@riverpod
Future<List<PaymentBreakdownItem>> platformPaymentBreakdown(Ref ref) {
  return ref
      .watch(adminRepositoryProvider)
      .getPaymentBreakdown(dimension: PaymentBreakdownDimension.platform);
}

@riverpod
Future<List<PaymentBreakdownItem>> productPaymentBreakdown(Ref ref) {
  return ref
      .watch(adminRepositoryProvider)
      .getPaymentBreakdown(dimension: PaymentBreakdownDimension.product);
}
