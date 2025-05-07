import { BaseAdService } from '../base-ad-service.ts';
import { UnityAdsParameters } from '../interfaces/ad-parameters.ts';
import { AdVerificationResult } from '../interfaces/ad-verification.ts';
import { UnityAdCallbackResponse } from '@shared/services/ad/base-ad-service.ts';
import CryptoJS from 'https://esm.sh/crypto-js@4.2.0';

const IOS_SECRET_KEY = '6f5f5206fa32f4f10e885b8e247c67c8';
const ANDROID_SECRET_KEY = 'dc33d67cb00d251d83164c5da4346c06';

export class UnityService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  validateParameters(params: UnityAdsParameters): boolean {
    const { sid, oid, hmac } = params;
    return sid !== '' && oid !== '' && hmac !== '';
  }

  extractParameters(url: URL): UnityAdsParameters {
    const params = url.searchParams;
    return {
      sid: params.get('sid') || '',
      oid: params.get('oid') || '',
      hmac: params.get('hmac') || '',
      user_id: params.get('sid') || '',
      reward_amount: 1,
      reward_type: 'free_charge_station',
      transaction_id: params.get('oid') || '',
      signature: params.get('hmac') || '',
      platform: 'unity',
      ad_network: 'unity',
    };
  }

  private async verifyHmac(
    params: UnityAdsParameters,
    secretKey: string,
  ): Promise<boolean> {
    try {
      // 1. sid와 oid만 사용하여 파라미터 정렬 및 문자열 생성
      const sortedParams = [
        ['oid', params.oid],
        ['sid', params.sid],
      ];

      const sortedParamString = sortedParams
        .map(([key, value]) => `${key}=${value}`)
        .join(',');

      // 2. MD5 해시 생성
      const expectedHmac = CryptoJS.HmacMD5(
        sortedParamString,
        secretKey,
      ).toString();

      return params.hmac.toLowerCase() === expectedHmac.toLowerCase();
    } catch (error) {
      console.error('HMAC 검증 중 오류:', {
        error,
        platform: secretKey === IOS_SECRET_KEY ? 'iOS' : 'Android',
      });
      return false;
    }
  }

  async verify(params: UnityAdsParameters): Promise<UnityAdCallbackResponse> {
    try {
      // 1. 필수 파라미터 검증
      if (!this.validateParameters(params)) {
        console.error('Unity Ads 필수 파라미터 검증 실패:', {
          sid: params.sid,
          oid: params.oid,
          hmac: params.hmac,
        });
        return {
          status: 400,
          body: 'Required parameters are missing.',
        };
      }
      // 2. HMAC 검증 (iOS와 Android 모두 확인)
      const iosValid = await this.verifyHmac(params, IOS_SECRET_KEY);
      const androidValid = await this.verifyHmac(params, ANDROID_SECRET_KEY);

      if (!iosValid && !androidValid) {
        console.error('Unity Ads HMAC 검증 실패 - iOS와 Android 모두 실패');
        return {
          status: 400,
          body: 'HMAC verification failed for both iOS and Android',
        };
      }
      // 3. 중복 트랜잭션 체크
      const isDuplicate = await this.checkExistingTransaction(
        params.oid,
        'transaction_unity',
      );

      if (isDuplicate) {
        return {
          status: 400,
          body: '이미 처리된 트랜잭션입니다.',
        };
      }

      // 4. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        return {
          status: 400,
          body: '사용자를 찾을 수 없습니다.',
        };
      }

      return {
        status: 200,
        body: '1',
      };
    } catch (error) {
      console.error('Unity Ads 검증 중 예상치 못한 오류:', {
        error,
        params: {
          sid: params.sid,
          oid: params.oid,
          hmac: params.hmac,
        },
      });
      return {
        status: 500,
        body: error instanceof Error ? error.message : '검증 실패',
      };
    }
  }

  async processTransaction(params: UnityAdsParameters): Promise<void> {
    // 트랜잭션 처리 전 중복 체크
    const isDuplicate = await this.checkExistingTransaction(
      params.oid,
      'transaction_unity',
    );
    if (isDuplicate) {
      throw new Error('이미 처리된 트랜잭션입니다.');
    }

    await this.addRewardHistory(
      params.user_id,
      params.reward_amount,
      params.oid,
    );

    const { error } = await this.supabase.from('transaction_unity').insert({
      transaction_id: params.oid,
      user_id: params.user_id,
      reward_amount: params.reward_amount,
      reward_type: params.reward_type,
      hmac: params.hmac,
    });

    await this.updateUserReward(params.user_id, params.reward_amount);

    if (error) throw error;
  }

  getResponseCode(error?: Error): string {
    if (!error) return '200';
    return '500';
  }

  async handleCallback(
    params: UnityAdsParameters,
  ): Promise<UnityAdCallbackResponse> {
    try {
      console.log('[Unity Ads 콜백 처리] 시작:', {
        sid: params.sid,
        oid: params.oid,
        hmac: params.hmac,
      });

      const verificationResult = await this.verify(params);

      if (verificationResult.status !== 200) {
        console.error('Unity Ads 검증 실패:', {
          status: verificationResult.status,
          body: verificationResult.body,
          params: {
            sid: params.sid,
            oid: params.oid,
            hmac: params.hmac,
          },
        });
        return verificationResult;
      }

      try {
        await this.processTransaction(params);
      } catch (error) {
        console.error('Unity Ads 트랜잭션 처리 중 오류:', {
          error,
          params: {
            user_id: params.user_id,
            reward_amount: params.reward_amount,
          },
        });
        return {
          status: 500,
          body:
            error instanceof Error
              ? error.message
              : '트랜잭션 처리 중 오류가 발생했습니다.',
        };
      }

      console.log('[Unity Ads 콜백 처리] 완료:', {
        sid: params.sid,
        oid: params.oid,
        hmac: params.hmac,
      });

      return {
        status: 200,
        body: '1',
      };
    } catch (error) {
      console.error('[Unity Ads 콜백 처리] 예상치 못한 오류:', {
        error,
        params: {
          sid: params.sid,
          oid: params.oid,
          hmac: params.hmac,
        },
      });
      return {
        status: 500,
        body:
          error instanceof Error
            ? error.message
            : '알 수 없는 오류가 발생했습니다.',
      };
    }
  }
}
