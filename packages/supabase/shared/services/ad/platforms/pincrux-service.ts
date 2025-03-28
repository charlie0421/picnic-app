import {
  BaseAdService,
  PincruxAdCallbackResponse,
} from '../base-ad-service.ts';
import { AdParameters } from '../interfaces/ad-parameters.ts';
import { createHmac } from 'node:crypto';

export class PincruxService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  validateParameters(params: AdParameters): boolean {
    const {
      user_id,
      reward_amount,
      reward_type,
      transaction_id,
      app_key,
      pub_key,
      app_title,
      menu_category,
    } = params;
    return !!(
      user_id &&
      reward_amount &&
      reward_type &&
      transaction_id &&
      app_key &&
      pub_key &&
      app_title &&
      menu_category
    );
  }

  extractParameters(url: URL): AdParameters {
    const params = url.searchParams;
    const appkey = params.get('appkey') || '';
    const pubkey = parseInt(params.get('pubkey') || '0', 10);
    const usrkey = params.get('usrkey') || '';
    const app_title = params.get('app_title') || '';
    const coin = params.get('coin') || '0';
    const transid = params.get('transid') || '';
    const signature = params.get('signature') || '';

    return {
      user_id: usrkey,
      reward_amount: parseInt(coin, 10),
      reward_type: 'free_charge_station',
      transaction_id: transid,
      signature,
      platform: 'pincrux',
      ad_network: 'pincrux',
      app_key: appkey,
      pub_key: pubkey,
      app_title,
      menu_category: params.get('menu_category1') || '',
    };
  }

  async verify(
    params: AdParameters,
  ): Promise<{ isValid: boolean; error?: string }> {
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
        params.transaction_id,
        'transaction_pincrux',
      );
      if (isDuplicate) {
        return {
          isValid: false,
          error: '이미 처리된 트랜잭션입니다.',
        };
      }

      // 4. 서명 검증
      const isValidSignature = this.verifySignature(params);
      if (!isValidSignature) {
        return {
          isValid: false,
          error: '서명이 유효하지 않습니다.',
        };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Error verifying Pincrux parameters:', error);
      return {
        isValid: false,
        error:
          error instanceof Error
            ? error.message
            : '검증 중 오류가 발생했습니다.',
      };
    }
  }

  async processTransaction(params: AdParameters): Promise<void> {
    await this.updateUserReward(params.user_id, params.reward_amount);
    await this.addRewardHistory(
      params.user_id,
      params.reward_amount,
      params.transaction_id,
    );

    const { error } = await this.supabase.from('transaction_pincrux').insert({
      transaction_id: params.transaction_id,
      reward_type: params.reward_type,
      reward_amount: params.reward_amount,
      app_key: params.app_key,
      pub_key: params.pub_key,
      app_title: params.app_title,
      menu_category: params.menu_category,
      user_id: params.user_id,
    });

    if (error) throw error;
  }

  private verifySignature(params: AdParameters): boolean {
    const signatureData = [
      params.app_key,
      params.pub_key,
      params.user_id,
      params.transaction_id,
      params.reward_amount.toString(),
      this.secretKey,
    ].join('|');

    const hmac = createHmac('sha256', this.secretKey);
    hmac.update(signatureData);
    const calculatedSignature = hmac.digest('hex');

    return calculatedSignature === params.signature;
  }

  getPincruxResponseCode(error?: Error): string {
    if (!error) return '00';

    const errorMessage = error.message.toLowerCase();
    if (errorMessage.includes('파라미터')) return '01';
    if (errorMessage.includes('서명')) return '02';
    if (errorMessage.includes('사용자')) return '05';
    if (errorMessage.includes('이미 처리된')) return '11';
    return '99';
  }

  getResponseCode(error?: Error): string {
    return this.getPincruxResponseCode(error);
  }

  async handleCallback(
    params: AdParameters,
  ): Promise<PincruxAdCallbackResponse> {
    try {
      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        return {
          status: 400,
          body: {
            code: this.getResponseCode(new Error(verificationResult.error)),
            error: verificationResult.error,
          },
        };
      }

      // 2. 트랜잭션 처리
      await this.processTransaction(params);

      return {
        status: 200,
        body: {
          code: this.getResponseCode(),
        },
      };
    } catch (error) {
      console.error('Error processing ad callback:', error);
      return {
        status: 500,
        body: {
          code: this.getResponseCode(error),
          error:
            error instanceof Error
              ? error.message
              : '알 수 없는 오류가 발생했습니다.',
        },
      };
    }
  }
}
