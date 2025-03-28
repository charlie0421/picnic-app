import { BaseAdService, PincruxAdCallbackResponse } from './base-ad-service.ts';
import { PincruxParameters } from './interfaces/ad-parameters.ts';
import { createHmac } from 'node:crypto';

export class PincruxAdService extends BaseAdService {
  validateParameters(params: PincruxParameters): boolean {
    return !!(
      params.user_id &&
      params.reward_amount &&
      params.reward_type &&
      params.transaction_id &&
      params.signature &&
      params.platform &&
      params.ad_network &&
      params.appkey &&
      params.pubkey &&
      params.usrkey &&
      params.app_title &&
      params.coin &&
      params.transid &&
      params.resign_flag &&
      params.commission &&
      params.menu_category1
    );
  }

  extractParameters(url: URL): PincruxParameters {
    const params = new URLSearchParams(url.search);
    return {
      user_id: params.get('user_id') ?? '',
      reward_amount: Number(params.get('reward_amount')),
      reward_type: params.get('reward_type') ?? '',
      transaction_id: params.get('transaction_id') ?? '',
      signature: params.get('signature') ?? '',
      platform: params.get('platform') ?? '',
      ad_network: params.get('ad_network') ?? '',
      appkey: params.get('appkey') ?? '',
      pubkey: Number(params.get('pubkey')),
      usrkey: params.get('usrkey') ?? '',
      app_title: params.get('app_title') ?? '',
      coin: params.get('coin') ?? '',
      transid: params.get('transid') ?? '',
      resign_flag: params.get('resign_flag') ?? '',
      commission: params.get('commission') ?? '',
      menu_category1: params.get('menu_category1') ?? '',
      menu_category2: params.get('menu_category2') ?? undefined,
      menu_category3: params.get('menu_category3') ?? undefined,
      menu_category4: params.get('menu_category4') ?? undefined,
      menu_category5: params.get('menu_category5') ?? undefined,
      ad_type: params.get('ad_type') ?? undefined,
      ad_unit_id: params.get('ad_unit_id') ?? undefined,
      ad_unit_name: params.get('ad_unit_name') ?? undefined,
    };
  }

  async verify(
    params: PincruxParameters,
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

  async processTransaction(params: PincruxParameters): Promise<void> {
    await this.processAdTransaction(params, 'pincrux');
  }

  private verifySignature(params: PincruxParameters): boolean {
    const signatureData = [
      params.appkey,
      params.pubkey,
      params.usrkey,
      params.transid,
      params.coin,
      this.secretKey,
    ].join('|');

    const hmac = createHmac('sha256', this.secretKey);
    hmac.update(signatureData);
    const calculatedSignature = hmac.digest('hex');

    return calculatedSignature === params.signature;
  }

  getResponseCode(error?: Error): string {
    if (!error) return '00';

    const errorMessage = error.message.toLowerCase();
    if (errorMessage.includes('파라미터')) return '01';
    if (errorMessage.includes('서명')) return '02';
    if (errorMessage.includes('사용자')) return '05';
    if (errorMessage.includes('이미 처리된')) return '11';
    return '99';
  }

  async handleCallback(
    params: PincruxParameters,
  ): Promise<PincruxAdCallbackResponse> {
    try {
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
