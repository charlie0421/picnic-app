import {
  BaseAdService,
  PincruxAdCallbackResponse,
} from '../base-ad-service.ts';
import { PincruxParameters } from '../interfaces/ad-parameters.ts';

export class PincruxService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  validateParameters(params: PincruxParameters): boolean {
    const { usrKey, coin, transid, appkey, pubkey, app_title } = params;
    return !!(usrKey && coin && transid && appkey && pubkey && app_title);
  }

  extractParameters(url: URL): PincruxParameters {
    const params = url.searchParams;
    const appkey = params.get('appkey') || '';
    const pubkey = parseInt(params.get('pubkey') || '0', 10);
    const usrkey = params.get('usrkey') || '';
    const app_title = params.get('app_title') || '';
    const coin = params.get('coin') || '0';
    const transid = params.get('transid') || '';
    const resign_flag = params.get('resign_flag') || '';
    const commission = params.get('commission') || '';
    const menu_category1 = params.get('menu_category1') || '';

    return {
      usrKey: usrkey,
      coin: coin,
      transid,
      appkey: appkey,
      pubkey: pubkey,
      app_title,
      menu_category1,
      resign_flag,
      commission,
    };
  }

  async verify(params: PincruxParameters): Promise<any> {
    try {
      // 1. 기본 파라미터 검증
      if (!this.validateParameters(params)) {
        return {
          isValid: false,
          code: '01',
          error: '필수 파라미터가 누락되었습니다.',
        };
      }

      // 2. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.usrKey);
      if (!userExists) {
        return {
          isValid: false,
          code: '05',
          error: '존재하지 않는 사용자입니다.',
        };
      }

      // 3. 중복 트랜잭션 확인
      const isDuplicate = await this.checkExistingTransaction(
        params.transid,
        'transaction_pincrux',
      );
      if (isDuplicate) {
        return {
          isValid: false,
          code: '11',
          error: '이미 처리된 트랜잭션입니다.',
        };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Error verifying Pincrux parameters:', error);
      return {
        isValid: false,
        code: '99',
        error:
          error instanceof Error
            ? error.message
            : '검증 중 오류가 발생했습니다.',
      };
    }
  }

  async processTransaction(params: PincruxParameters): Promise<void> {
    await this.updateUserReward(params.usrKey, parseInt(params.coin, 10));
    await this.addRewardHistory(
      params.usrKey,
      parseInt(params.coin, 10),
      params.transid,
    );

    const { error } = await this.supabase.from('transaction_pincrux').insert({
      transaction_id: params.transid,
      app_key: params.appkey,
      pub_key: params.pubkey,
      app_title: params.app_title,
      menu_category1: params.menu_category1,
      usr_key: params.usrKey,
      reward_amount: parseInt(params.coin, 10),
      reward_type: 'pincrux',
      commission: parseInt(params.commission, 10),
    });

    if (error) throw error;
  }

  getResponseCode(error?: Error): string {
    if (!error) return '200';
    return '500';
  }

  async handleCallback(
    params: PincruxParameters,
  ): Promise<PincruxAdCallbackResponse> {
    try {
      console.log('Pincrux 콜백 처리 시작');
      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        console.log('Pincrux 콜백 파라미터 검증 실패', verificationResult);
        return {
          status: 400,
          body: {
            code: verificationResult.code,
            error: verificationResult.error,
          },
        };
      }

      // 2. 트랜잭션 처리
      try {
        await this.processTransaction(params);
      } catch (error) {
        console.error('Error processing transaction:', error);
        return {
          status: 500,
          body: {
            code: this.getResponseCode(error),
            error:
              error instanceof Error
                ? error.message
                : '트랜잭션 처리 중 오류가 발생했습니다.',
          },
        };
      }

      console.log('Pincrux 콜백 처리 완료', params);

      return {
        status: 200,
        body: {
          code: '00',
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
