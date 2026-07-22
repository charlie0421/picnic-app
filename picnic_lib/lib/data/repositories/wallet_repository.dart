import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletRepository {
  const WalletRepository(this.client);

  final SupabaseClient client;

  Future<WalletSummaryModel> getSummary() async {
    final value = await client.rpc('get_wallet_summary');
    return WalletSummaryModel.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    final value = await client.rpc(
      'get_currency_history',
      params: {
        'p_currency': currency.wireValue,
        'p_cursor': cursor,
        'p_limit': limit,
      },
    );
    return CurrencyHistoryPageModel.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }
}
