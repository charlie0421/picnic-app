import { BaseAdService } from '../base-ad-service.ts';
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";

export class UnityService extends BaseAdService {
  secretKeys: { ios: string, android: string };

  constructor(secretKeys: { ios: string, android: string }) {
    super(''); 
    this.secretKeys = secretKeys;
  }

  extractParameters(url: URL): any {
    const params = {};
    for (const [key, value] of url.searchParams.entries()) {
      params[key] = value;
    }
    params.user_id = params.sid; 
    params.transaction_id = params.oid;
    params.reward_amount = 1; 
    params.reward_type = 'unity_reward';
    return params;
  }

  validateParameters(params: any): boolean {
    const { oid, sid, hmac } = params;
    return !!(oid && sid && hmac);
  }

  verifySignature(params: any): { isValid: boolean; platform?: 'ios' | 'android' } {
    const receivedHmac = params.hmac;

    const paramsToSign = { ...params };
    delete paramsToSign.hmac;
    delete paramsToSign.user_id;
    delete paramsToSign.transaction_id;
    delete paramsToSign.reward_amount;
    delete paramsToSign.reward_type;

    const sortedKeys = Object.keys(paramsToSign).sort();
    const message = sortedKeys
      .map(key => `${key}=${paramsToSign[key]}`)
      .join(',');

    if (this.secretKeys.ios) {
        const iosHmac = createHmac('md5', this.secretKeys.ios).update(message).digest('hex');
        if (iosHmac === receivedHmac) {
            console.log(`[Verify] iOS 키로 서명 검증 성공.`);
            return { isValid: true, platform: 'ios' };
        }
    }

    if (this.secretKeys.android) {
        const androidHmac = createHmac('md5', this.secretKeys.android).update(message).digest('hex');
        if (androidHmac === receivedHmac) {
            console.log(`[Verify] Android 키로 서명 검증 성공.`);
            return { isValid: true, platform: 'android' };
        }
    }
    
    console.error(`[Verify] 모든 키로 서명 검증 실패. Message: "${message}", Received: ${receivedHmac}`);
    return { isValid: false };
  }

  async verify(params: any): Promise<{ isValid: boolean; error?: string, status?: 'duplicate' }> {
    try {
      if (!this.validateParameters(params)) {
        return { isValid: false, error: '필수 파라미터(oid, sid, hmac)가 누락되었습니다.' };
      }
      
      const isDuplicate = await this.checkExistingTransaction(params.transaction_id, 'transaction_unity');
      if (isDuplicate) {
        // 중복인 경우, 에러가 아닌 'duplicate' 상태를 반환
        return { isValid: false, status: 'duplicate', error: '이미 처리된 트랜잭션입니다.' };
      }

      const signatureResult = this.verifySignature(params);
      if (!signatureResult.isValid) {
        return { isValid: false, error: 'HMAC 서명이 유효하지 않습니다 (iOS & Android 키 모두 실패).' };
      }
      
      params.platform = signatureResult.platform;

      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        return { isValid: false, error: '존재하지 않는 사용자입니다.' };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Error verifying Unity parameters:', error);
      return { isValid: false, error: error instanceof Error ? error.message : '검증 중 오류가 발생했습니다.' };
    }
  }

  async processTransaction(params: any): Promise<void> {
    await this.updateUserReward(params.user_id, params.reward_amount);
    await this.addRewardHistory(params.user_id, params.reward_amount, params.transaction_id);
    const { error } = await this.supabase.from('transaction_unity').insert({
      transaction_id: params.transaction_id,
      user_id: params.user_id,
      reward_amount: params.reward_amount,
      reward_type: params.reward_type,
      platform: params.platform,
      hmac: params.hmac,
    });
    if (error) throw error;
  }
  
  getResponseCode(error?: any): string {
    if (!error) return '1';
    return '0';
  }

  async handleCallback(params: any): Promise<{ status: number; body: any }> {
    try {
      console.log('콜백 처리 시작 (GET):', params);
      const verificationResult = await this.verify(params);

      if (!verificationResult.isValid) {
        // 중복 트랜잭션인 경우, 에러 로깅 없이 성공으로 응답
        if (verificationResult.status === 'duplicate') {
          console.log(`중복 콜백 수신 (정상 무시): ${params.transaction_id}`);
          return { status: 200, body: { success: true, message: 'Duplicate transaction' } };
        }
        // 그 외의 검증 실패는 에러 로깅
        console.error('검증 실패:', verificationResult.error);
        return { status: 400, body: { success: false, error: verificationResult.error } };
      }

      await this.processTransaction(params);

      console.log('콜백 처리 완료:', params);
      return { status: 200, body: { success: true } };
    } catch (error) {
      console.error('콜백 처리 중 예상치 못한 오류 발생:', error);
      return { status: 500, body: { success: false, error: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다.' } };
    }
  }
}
