import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletRepository {
  const WalletRepository(this.client);

  final SupabaseClient client;

  /// 세션이 없는 사용자의 지갑.
  ///
  /// 서버가 `WALLET_UNAUTHENTICATED` 로 답할 때 돌려주는 값이자, 클라이언트가
  /// 세션이 없다는 것을 **이미 알고 있을 때** 서버를 거치지 않고 쓰는 값이다.
  /// 지갑 RPC 는 `SECURITY DEFINER` 읽기라 `anon` EXECUTE 가 설계상 회수돼
  /// 있고, 세션 없이 보낸 읽기가 받아올 수 있는 것은 잔액이 아니라 권한 오류뿐이다.
  static WalletSummaryModel signedOut() => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.now().toUtc(),
  );

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

      return signedOut();
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
