import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletRepository {
  const WalletRepository(this.client);

  final SupabaseClient client;

  Future<WalletSummaryModel> getSummary() async {
    try {
      final value = await client.rpc('get_wallet_summary');
      return WalletSummaryModel.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
    } on PostgrestException catch (error) {
      if (error.code != 'P0001' || error.message != 'WALLET_UNAUTHENTICATED') {
        rethrow;
      }

      return WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.zero,
        bonus: BigInt.zero,
        cotton: BigInt.zero,
        cottonExpiringAmount: BigInt.zero,
        cottonNextExpiresAt: null,
        snapshotAt: DateTime.now().toUtc(),
      );
    }
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
