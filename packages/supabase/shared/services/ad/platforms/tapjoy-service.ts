import CryptoJS from 'https://esm.sh/crypto-js@4.2.0';
import {
  BaseAdService,
  DefaultAdCallbackResponse,
  TapjoyAdCallbackResponse,
} from '../base-ad-service.ts';
import { TapjoyParameters } from '../interfaces/ad-parameters.ts';

export class TapjoyService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  private async verifySignature(
    params: TapjoyParameters,
    signature: string,
    platform?: string,
  ): Promise<boolean> {
    try {
      let secret = this.secretKey;
      if (!secret) {
        // 플랫폼별 secret key 가져오기
        const platformKey =
          platform === 'ios'
            ? Deno.env.get('TAPJOY_SECRET_IOS')
            : Deno.env.get('TAPJOY_SECRET_ANDROID');

        if (!platformKey) {
          console.error(
            `TAPJOY_SECRET_${platform?.toUpperCase()} 환경 변수가 설정되지 않았습니다.`,
          );
          return false;
        }
        secret = platformKey;
      }

      const source = `${params.id}:${params.snuid}:${params.currency}:${secret}`;
      const expectedVerifier = CryptoJS.MD5(source).toString();

      if (expectedVerifier !== signature) {
        console.error('유효하지 않은 서명입니다.', {
          expectedVerifier,
          providedVerifier: signature,
        });
        return false;
      }
      return true;
    } catch (error) {
      console.error('Error during signature verification:', error);
      return false;
    }
  }

  validateParameters(params: TapjoyParameters): boolean {
    const { platform, currency, user_id, id, snuid, verifier } = params;
    return !!(platform && currency && user_id && id && snuid && verifier);
  }

  extractParameters(url: URL): TapjoyParameters {
    const params = url.searchParams;
    return {
      user_id: params.get('snuid') || '',
      currency: parseInt(params.get('currency') || '0', 10),
      id: params.get('id') || '',
      snuid: params.get('snuid') || '',
      verifier: params.get('verifier') || '',
      platform: params.get('platform') || '',
      ad_network: 'tapjoy',
      mac_address: params.get('mac_address') || '',
    };
  }

  async verify(params: TapjoyParameters): Promise<any> {
    try {
      // 1. 기본 파라미터 검증
      if (!this.validateParameters(params)) {
        return {
          isValid: false,
          error: '필수 파라미터가 누락되었습니다.',
        };
      }

      // 2. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        return {
          isValid: false,
          error: '존재하지 않는 사용자입니다.',
        };
      }

      // 3. 중복 트랜잭션 확인
      const isDuplicate = await this.checkExistingTransaction(
        params.id,
        'transaction_tapjoy',
      );
      if (isDuplicate) {
        return {
          isValid: false,
          error: '이미 처리된 트랜잭션입니다.',
        };
      }

      // 4. 서명 검증
      const isValid = await this.verifySignature(
        params,
        params.verifier,
        params.platform.toLowerCase(),
      );

      if (!isValid) {
        return {
          isValid: false,
          error: '서명이 유효하지 않습니다.',
        };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Error verifying Tapjoy parameters:', error);
      return {
        isValid: false,
        error:
          error instanceof Error
            ? error.message
            : '검증 중 오류가 발생했습니다.',
      };
    }
  }

  async processTransaction(params: TapjoyParameters): Promise<void> {
    await this.updateUserReward(params.user_id, params.currency);

    await this.addRewardHistory(params.user_id, params.currency, params.id);
    const { error } = await this.supabase.from('transaction_tapjoy').insert({
      transaction_id: params.id,
      reward_type: 'MISSION',
      reward_amount: params.currency,
      user_id: params.user_id,
      platform: params.platform,
      verifier: params.verifier,
    });

    if (error) throw error;
  }

  getResponseCode(error?: Error): string {
    if (!error) return '200';
    return '500';
  }

  async handleCallback(
    params: TapjoyParameters,
  ): Promise<TapjoyAdCallbackResponse> {
    try {
      console.log('콜백 처리 시작:', params);

      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
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
      console.error('Error processing ad callback:', error);
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
