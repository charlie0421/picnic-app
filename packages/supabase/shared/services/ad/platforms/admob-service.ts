import {
  BaseAdService,
  DefaultAdCallbackResponse,
  AdMobAdCallbackResponse,
} from '../base-ad-service.ts';
import { AdMobParameters } from '../interfaces/ad-parameters.ts';

export class AdMobService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  validateParameters(params: AdMobParameters): boolean {
    const { user_id, reward_amount, reward_type, transaction_id, signature } =
      params;
    return !!(
      user_id &&
      reward_amount &&
      reward_type &&
      transaction_id &&
      signature
    );
  }

  extractParameters(url: URL): AdMobParameters {
    const params = url.searchParams;
    return {
      user_id: params.get('user_id') || '',
      reward_amount: parseInt(params.get('reward_amount') || '0', 10),
      reward_type: params.get('reward_type') || 'free_charge_station',
      transaction_id: params.get('transaction_id') || '',
      signature: params.get('signature') || '',
      platform: params.get('platform') || '',
      ad_network: params.get('ad_network') || '',
      key_id: params.get('key_id') || '',
    };
  }

  async verify(
    params: AdMobParameters,
  ): Promise<{ isValid: boolean; error?: string }> {
    try {
      // 1. 기본 파라미터 검증
      if (!this.validateParameters(params)) {
        return {
          isValid: false,
          error: '필수 파라미터가 누락되었습니다.',
        };
      }

      // 2. 디버그 모드 체크
      if (params.user_id === 'fakeForAdDebugLog') {
        return { isValid: true };
      }

      // 3. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        return {
          isValid: false,
          error: '존재하지 않는 사용자입니다.',
        };
      }

      // 4. 중복 트랜잭션 확인
      const isDuplicate = await this.checkExistingTransaction(
        params.transaction_id,
        'transaction_admob',
      );
      if (isDuplicate) {
        return {
          isValid: false,
          error: '이미 처리된 트랜잭션입니다.',
        };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Error verifying AdMob parameters:', error);
      return {
        isValid: false,
        error:
          error instanceof Error
            ? error.message
            : '검증 중 오류가 발생했습니다.',
      };
    }
  }

  async processTransaction(params: AdMobParameters): Promise<void> {
    if (params.user_id === 'fakeForAdDebugLog') {
      console.log('디버깅 모드: 데이터베이스 업데이트를 건너뜁니다.');
      return;
    }

    await this.processAdTransaction(params, 'admob');
  }

  getResponseCode(error?: Error): string {
    if (!error) return '200';
    return '500';
  }

  async handleCallback(
    params: AdMobParameters,
  ): Promise<AdMobAdCallbackResponse> {
    try {
      console.log('콜백 처리 시작:', params);

      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        console.error('검증 실패:', verificationResult.error);
        return {
          status: 400,
          body: {
            success: false,
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
            success: false,
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
          success: true,
        },
      };
    } catch (error) {
      console.error('콜백 처리 중 예상치 못한 오류 발생:', error);
      return {
        status: 500,
        body: {
          success: false,
          error:
            error instanceof Error
              ? error.message
              : '알 수 없는 오류가 발생했습니다.',
        },
      };
    }
  }
}
