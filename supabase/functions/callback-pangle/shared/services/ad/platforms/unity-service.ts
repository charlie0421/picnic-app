import { BaseAdService } from '../base-ad-service.ts';

export class UnityService extends BaseAdService {
  constructor(secretKey: string) {
    super(secretKey);
  }

  validateParameters(params: any): boolean {
    // Unity 콜백 사양에 맞게 수정 필요
    const { user_id, reward_amount, reward_type, transaction_id, signature } = params;
    return !!(user_id && reward_amount && reward_type && transaction_id && signature);
  }

  extractParameters(url: URL): any {
    const params = url.searchParams;
    // Unity 콜백 사양에 맞게 수정 필요
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

  async verify(params: any): Promise<{ isValid: boolean; error?: string }> {
    try {
      if (!this.validateParameters(params)) {
        return { isValid: false, error: '필수 파라미터가 누락되었습니다.' };
      }

      if (params.user_id === 'fakeForAdDebugLog') {
        return { isValid: true };
      }

      const userExists = await this.checkUserExists(params.user_id);
      if (!userExists) {
        return { isValid: false, error: '존재하지 않는 사용자입니다.' };
      }

      const isDuplicate = await this.checkExistingTransaction(params.transaction_id, 'transaction_unity');
      if (isDuplicate) {
        return { isValid: false, error: '이미 처리된 트랜잭션입니다.' };
      }

      // Unity 서명 검증 로직 추가 필요
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
      // key_id: params.key_id, // Unity에서 이 값을 제공하는지 확인 필요
    });
    if (error) throw error;
  }
  
  getResponseCode(error?: any): string {
    if (!error) return 'OK';
    return 'FAILED';
  }

  async handleCallback(params: any): Promise<{ status: number; body: any }> {
    try {
      console.log('콜백 처리 시작:', params);
      const verificationResult = await this.verify(params);
      if (!verificationResult.isValid) {
        console.error('검증 실패:', verificationResult.error);
        return { status: 400, body: { success: false, error: verificationResult.error, responseCode: this.getResponseCode(verificationResult.error) } };
      }

      await this.processTransaction(params);

      console.log('콜백 처리 완료:', params);
      return { status: 200, body: { success: true, responseCode: this.getResponseCode() } };
    } catch (error) {
      console.error('콜백 처리 중 예상치 못한 오류 발생:', error);
      return { status: 500, body: { success: false, error: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다.', responseCode: this.getResponseCode(error) } };
    }
  }
}
