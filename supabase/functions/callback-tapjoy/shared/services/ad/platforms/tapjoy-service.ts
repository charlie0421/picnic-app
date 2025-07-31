import CryptoJS from 'https://esm.sh/crypto-js@4.2.0';
import { BaseAdService } from '../base-ad-service.ts';

export class TapjoyService extends BaseAdService {
  constructor(secretKey: string){
    super(secretKey);
  }

  async verifySignature(params: any, signature: string, platform: string): Promise<boolean> {
    const { id: transactionId } = params;
    console.log(`[Verify Signature] (${transactionId}) 서명 검증 시작...`);
    
    try {
      const platformKey = platform === 'ios' ? Deno.env.get('TAPJOY_SECRET_IOS') : Deno.env.get('TAPJOY_SECRET_ANDROID');
      if (!platformKey) {
        console.error(`[Verify Signature] (${transactionId}) TAPJOY_SECRET_${platform?.toUpperCase()} 환경 변수가 설정되지 않았습니다.`);
        return false;
      }
      
      const secret = platformKey;
      const source = `${params.id}:${params.snuid}:${params.currency}:${secret}`;
      const expectedVerifier = CryptoJS.MD5(source).toString();
      
      if (expectedVerifier !== signature) {
        console.error(`[Verify Signature] (${transactionId}) 서명 불일치.`, {
          source,
          expectedVerifier,
          providedVerifier: signature,
        });
        return false;
      }

      console.log(`[Verify Signature] (${transactionId}) 서명 검증 성공.`);
      return true;
    } catch (error) {
      console.error(`[Verify Signature] (${transactionId}) 서명 검증 중 오류:`, error);
      return false;
    }
  }

  validateParameters(params: any): boolean {
    const { id: transactionId } = params;
    console.log(`[Validate Parameters] (${transactionId}) 필수 파라미터 검증 시작...`);
    const { platform, currency, user_id, id, snuid, verifier } = params;
    const isValid = !!(platform && currency && user_id && id && snuid && verifier);
    if (!isValid) {
      console.error(`[Validate Parameters] (${transactionId}) 필수 파라미터 누락.`, params);
    } else {
      console.log(`[Validate Parameters] (${transactionId}) 필수 파라미터 확인 완료.`);
    }
    return isValid;
  }

  extractParameters(url: URL): any {
    const params = url.searchParams;
    const transactionId = params.get('id') || `no-id-${Date.now()}`;
    console.log(`[Extract Parameters] (${transactionId}) URL에서 파라미터 추출 시작...`);
    const extractedParams = {
      user_id: params.get('snuid') || '',
      currency: parseInt(params.get('currency') || '0', 10),
      id: transactionId,
      snuid: params.get('snuid') || '',
      verifier: params.get('verifier') || '',
      platform: params.get('platform') || '',
      ad_network: 'tapjoy',
      mac_address: params.get('mac_address') || '',
    };
    console.log(`[Extract Parameters] (${transactionId}) 파라미터 추출 완료:`, extractedParams);
    return extractedParams;
  }

  async verify(params: any): Promise<{ isValid: boolean; error?: string; status?: 'duplicate' }> {
    const { id: transactionId, user_id } = params;
    console.log(`[Verify] (${transactionId}) 전체 검증 시작...`);
    
    if (!this.validateParameters(params)) {
      return { isValid: false, error: '필수 파라미터가 누락되었습니다.' };
    }

    const isDuplicate = await this.checkExistingTransaction(transactionId, 'transaction_tapjoy');
    if (isDuplicate) {
      return { isValid: false, status: 'duplicate', error: '이미 처리된 트랜잭션입니다.' };
    }

    const userExists = await this.checkUserExists(user_id);
    if (!userExists) {
      console.error(`[Verify] (${transactionId}) 존재하지 않는 사용자입니다: ${user_id}`);
      return { isValid: false, error: '존재하지 않는 사용자입니다.' };
    }

    const isSignatureValid = await this.verifySignature(params, params.verifier, params.platform.toLowerCase());
    if (!isSignatureValid) {
      return { isValid: false, error: '서명이 유효하지 않습니다.' };
    }

    console.log(`[Verify] (${transactionId}) 모든 검증 완료.`);
    return { isValid: true };
  }

  async processTransaction(params: any): Promise<void> {
    const { id: transactionId, user_id, currency } = params;
    console.log(`[Process Transaction] (${transactionId}) 트랜잭션 처리 시작 (사용자: ${user_id}, 보상: ${currency}).`);
    
    console.log(`[Process Transaction] (${transactionId}) 사용자 보상 업데이트 중...`);
    await this.updateUserReward(user_id, currency);
    console.log(`[Process Transaction] (${transactionId}) 사용자 보상 업데이트 완료.`);
    
    console.log(`[Process Transaction] (${transactionId}) 보상 내역 기록 중...`);
    await this.addRewardHistory(user_id, currency, transactionId);
    console.log(`[Process Transaction] (${transactionId}) 보상 내역 기록 완료.`);
    
    console.log(`[Process Transaction] (${transactionId}) 트랜잭션 테이블에 기록 중...`);
    const { error } = await this.supabase.from('transaction_tapjoy').insert({
      transaction_id: transactionId,
      reward_type: 'MISSION',
      reward_amount: currency,
      user_id: user_id,
      platform: params.platform,
      verifier: params.verifier,
    });
    if (error) {
      console.error(`[Process Transaction] (${transactionId}) 트랜잭션 테이블 삽입 오류:`, error);
      throw error;
    }
    console.log(`[Process Transaction] (${transactionId}) 트랜잭션 테이블 기록 완료.`);
  }

  getResponseCode(error: any): string {
    return error ? '500' : '200';
  }

  async handleCallback(params: any): Promise<{ status: number; body: any }> {
    const transactionId = params.id || `no-id-${Date.now()}`;
    console.log(`[Handle Callback] (${transactionId}) 콜백 처리 시작:`, params);
    
    try {
      const verificationResult = await this.verify(params);

      if (!verificationResult.isValid) {
        if (verificationResult.status === 'duplicate') {
          console.log(`[Handle Callback] (${transactionId}) 중복 콜백 수신 (정상 무시).`);
          return { status: 200, body: { success: true, message: 'Duplicate transaction' } };
        }
        
        console.error(`[Handle Callback] (${transactionId}) 검증 실패:`, verificationResult.error);
        return { status: 400, body: { success: false, error: verificationResult.error } };
      }

      await this.processTransaction(params);

      console.log(`[Handle Callback] (${transactionId}) 콜백 처리 성공.`);
      return { status: 200, body: { success: true } };
    } catch (error) {
      console.error(`[Handle Callback] (${transactionId}) 콜백 처리 중 예상치 못한 오류 발생:`, error);
      return {
        status: 500,
        body: { success: false, error: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다.' },
      };
    }
  }
}
