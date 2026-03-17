import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';

/// JMA 투표 API 호출 로직을 담당하는 헬퍼
class JmaVotingHelper {
  JmaVotingHelper._();

  /// 429 응답 시 자동 재시도하는 JMA 투표 API 호출
  ///
  /// [isMounted] 콜백으로 위젯의 mounted 상태를 확인합니다.
  /// mounted가 아닌 경우 재시도하지 않고 현재 응답을 반환합니다.
  static Future<dynamic> invokeJmaVotingWithRetry({
    required int voteId,
    required int voteItemId,
    required int amount,
    required String userId,
    required int starCandyUsage,
    required int starCandyBonusUsage,
    int retryCount = 0,
    bool Function()? isMounted,
  }) async {
    final response = await supabase.functions.invoke(
      'jma-voting-v2',
      body: {
        'vote_id': voteId,
        'vote_item_id': voteItemId,
        'amount': amount,
        'star_candy_usage': starCandyUsage,
        'star_candy_bonus_usage': starCandyBonusUsage,
        'user_id': userId,
      },
    );

    // 429 응답이고 retryable이면 3초 후 1회 재시도
    if (response.status == 429 && retryCount < 1) {
      final data = response.data as Map<String, dynamic>?;
      final isRetryable = data?['retryable'] == true;

      if (isRetryable) {
        logger.d('JMA Voting rate limited, retrying in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));

        if (isMounted != null && !isMounted()) return response;

        return invokeJmaVotingWithRetry(
          voteId: voteId,
          voteItemId: voteItemId,
          amount: amount,
          userId: userId,
          starCandyUsage: starCandyUsage,
          starCandyBonusUsage: starCandyBonusUsage,
          retryCount: retryCount + 1,
          isMounted: isMounted,
        );
      }
    }

    return response;
  }

  /// JMA 환전 + 투표 실행
  ///
  /// 투표 API를 호출하고 응답을 반환합니다.
  /// 위젯 상태에 의존하는 UI 로직(에러 다이얼로그 등)은 호출자가 처리합니다.
  static Future<dynamic> performExchangeAndVoting({
    required int voteId,
    required int voteItemId,
    required int totalVoteAmount,
    required String userId,
    required int starCandyUsage,
    required int starCandyBonusUsage,
    bool Function()? isMounted,
  }) async {
    return invokeJmaVotingWithRetry(
      voteId: voteId,
      voteItemId: voteItemId,
      amount: totalVoteAmount,
      userId: userId,
      starCandyUsage: starCandyUsage,
      starCandyBonusUsage: starCandyBonusUsage,
      isMounted: isMounted,
    );
  }
}
