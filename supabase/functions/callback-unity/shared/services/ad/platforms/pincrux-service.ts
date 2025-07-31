import { BaseAdService } from '../base-ad-service.ts';
export class PincruxService extends BaseAdService {
  constructor(secretKey){
    super(secretKey);
  }
  validateParameters(params) {
    const { usrKey, coin, transid, appkey, pubkey, app_title, menu_category1 } = params;
    return !!(usrKey && coin && transid && appkey && pubkey && app_title && menu_category1);
  }
  extractParameters(url) {
    const params = url.searchParams;
    const appkey = params.get('appkey') || '';
    const pubkey = parseInt(params.get('pubkey') || '0', 10);
    const usrkey = params.get('usrkey') || '';
    const app_title = params.get('app_title') || '';
    const coin = params.get('coin') || '0';
    const transid = params.get('transid') || '';
    const resign_flag = params.get('resign_flag') || '';
    const commission = params.get('commission') || '';
    return {
      usrKey: usrkey,
      coin: coin,
      transid,
      appkey: appkey,
      pubkey: pubkey,
      app_title,
      menu_category1: params.get('menu_category1') || '',
      resign_flag,
      commission
    };
  }
  async verify(params) {
    try {
      // 1. 기본 파라미터 검증
      if (!this.validateParameters(params)) {
        return {
          isValid: false,
          error: '필수 파락라미터가 누락되었습니다.'
        };
      }
      // 2. 사용자 존재 여부 확인
      const userExists = await this.checkUserExists(params.usrKey);
      if (!userExists) {
        return {
          isValid: false,
          error: '존재하지 않는 사용자입니다.'
        };
      }
      // 3. 중복 트랜잭션 확인
      const isDuplicate = await this.checkExistingTransaction(params.transid, 'transaction_pincrux');
      if (isDuplicate) {
        return {
          isValid: false,
          error: '이미 처리된 트랜잭션입니다.'
        };
      }
      // 4. 서명 검증
      return {
        isValid: true
      };
    } catch (error) {
      console.error('Error verifying Pincrux parameters:', error);
      return {
        isValid: false,
        error: error instanceof Error ? error.message : '검증 중 오류가 발생했습니다.'
      };
    }
  }
  async processTransaction(params) {
    await this.updateUserReward(params.usrKey, parseInt(params.coin, 10));
    await this.addRewardHistory(params.usrKey, parseInt(params.coin, 10), params.transid);
    const { error } = await this.supabase.from('transaction_pincrux').insert({
      transaction_id: params.transid,
      app_key: params.appkey,
      pub_key: params.pubkey,
      app_title: params.app_title,
      menu_category1: params.menu_category1,
      usrKey: params.usrKey
    });
    if (error) throw error;
  }
  getPincruxResponseCode(error) {
    if (!error) return '00';
    const errorMessage = error.message.toLowerCase();
    if (errorMessage.includes('파라미터')) return '01';
    if (errorMessage.includes('서명')) return '02';
    if (errorMessage.includes('사용자')) return '05';
    if (errorMessage.includes('이미 처리된')) return '11';
    return '99';
  }
  getResponseCode(error) {
    return this.getPincruxResponseCode(error);
  }
  async handleCallback(params) {
    try {
      console.log('Pincrux 콜백 처리 시작');
      // 1. 파라미터 검증
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        return {
          status: 400,
          body: {
            code: this.getResponseCode(new Error(verificationResult.error)),
            error: verificationResult.error
          }
        };
      }
      // 2. 트랜잭션 처리
      await this.processTransaction(params);
      return {
        status: 200,
        body: {
          code: this.getResponseCode()
        }
      };
    } catch (error) {
      console.error('Error processing ad callback:', error);
      return {
        status: 500,
        body: {
          code: this.getResponseCode(error),
          error: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다.'
        }
      };
    }
  }
}
