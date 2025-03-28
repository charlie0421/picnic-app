import { BaseAdService, PangleAdCallbackResponse } from '../base-ad-service.ts';
import { PangleParameters } from '../interfaces/ad-parameters.ts';

export class PangleService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
    console.log('PangleService 초기화 완료');
  }

  validateParameters(params: PangleParameters): boolean {
    const { user_id, reward_amount, reward_type, transaction_id, signature } =
      params;
    const isValid = !!(
      user_id &&
      reward_amount &&
      reward_type &&
      transaction_id &&
      signature
    );
    return isValid;
  }

  extractParameters(url: URL): PangleParameters {
    const params = url.searchParams;
    const trans_id = params.get('trans_id') || '';
    const reward_amount = parseInt(params.get('reward_amount') || '0', 10);
    const extra = params.get('extra') || '';
    const sign = params.get('sign') || '';

    let user_id = params.get('user_id') || '';
    let reward_type = 'free_charge_station';
    let platform = '';

    if (extra) {
      try {
        const extraArray = extra.split(',');
        user_id = extraArray[0] || user_id;
        platform = extraArray[1] || platform;

        const parsedData = JSON.parse(extra);
        reward_type = parsedData.reward_type || reward_type;
        console.log('extra 파라미터 파싱 결과:', {
          user_id,
          platform,
          reward_type,
        });
      } catch (error) {
        console.log(`extra 파라미터 파싱 실패: ${error.message}, 기본값 사용`);
      }
    }

    const result = {
      user_id,
      reward_amount,
      reward_type,
      transaction_id: trans_id,
      signature: sign,
      platform,
      ad_network: 'pangle',
    };
    return result;
  }

  async verify(
    params: PangleParameters,
  ): Promise<{ isValid: boolean; error?: string }> {
    try {
      // 1. 기본 파라미터 검증
      if (!this.validateParameters(params)) {
        console.error('기본 파라미터 검증 실패');
        return {
          isValid: false,
          error: '필수 파라미터가 누락되었습니다.',
        };
      }

      // 2. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        console.error('사용자 존재하지 않음:', params.user_id);
        return {
          isValid: false,
          error: '존재하지 않는 사용자입니다.',
        };
      }

      // 3. 중복 트랜잭션 확인
      const isDuplicate = await this.checkExistingTransaction(
        params.transaction_id,
        'transaction_pangle',
      );
      if (isDuplicate) {
        console.error('중복 트랜잭션 발견:', params.transaction_id);
        return {
          isValid: false,
          error: '이미 처리된 트랜잭션입니다.',
        };
      }
      return { isValid: true };
    } catch (error) {
      console.error('검증 중 오류 발생:', error);
      return {
        isValid: false,
        error:
          error instanceof Error
            ? error.message
            : '검증 중 오류가 발생했습니다.',
      };
    }
  }

  async processTransaction(params: PangleParameters): Promise<void> {
    try {
      await this.updateUserReward(params.user_id, params.reward_amount);

      await this.addRewardHistory(
        params.user_id,
        params.reward_amount,
        params.transaction_id,
      );

      const { error } = await this.supabase.from('transaction_pangle').insert({
        transaction_id: params.transaction_id,
        reward_type: params.reward_type,
        reward_amount: params.reward_amount,
        signature: params.signature,
        ad_network: 'pangle',
        platform: params.platform,
        user_id: params.user_id,
      });

      if (error) {
        console.error('트랜잭션 기록 추가 실패:', error);
        throw error;
      }
    } catch (error) {
      console.error('트랜잭션 처리 중 오류 발생:', error);
      throw error;
    }
  }

  getResponseCode(error?: Error): string {
    const code = !error ? '200' : '500';
    return code;
  }

  async handleCallback(
    params: PangleParameters,
  ): Promise<PangleAdCallbackResponse> {
    try {
      console.log('콜백 처리 시작:', params);

      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        console.error('검증 실패:', verificationResult.error);
        return {
          status: 400,
          body: {
            isValid: false,
            error: verificationResult.error,
          },
        };
      }

      // 2. 트랜잭션 처리
      try {
        await this.processTransaction(params);
      } catch (error) {
        console.error('트랜잭션 처리 중 오류:', error);
        return {
          status: 500,
          body: {
            isValid: false,
            error:
              error instanceof Error
                ? error.message
                : '트랜잭션 처리 중 오류가 발생했습니다.',
          },
        };
      }

      console.log('콜백 처리 완료 : ', params);
      return {
        status: 200,
        body: {
          isValid: true,
        },
      };
    } catch (error) {
      console.error('콜백 처리 중 예상치 못한 오류 발생:', error);
      return {
        status: 500,
        body: {
          isValid: false,
          error:
            error instanceof Error
              ? error.message
              : '알 수 없는 오류가 발생했습니다.',
        },
      };
    }
  }
}
