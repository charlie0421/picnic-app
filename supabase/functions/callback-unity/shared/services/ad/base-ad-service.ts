import { createClient } from '@supabase/supabase-js';
import { getNextMonth15thAt9AM } from './utils/date.ts';

export class BaseAdService {
  supabase;
  secretKey;

  constructor(secretKey: string){
    this.secretKey = secretKey;
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Supabase URL 또는 Service Role Key가 환경 변수에 설정되지 않았습니다.');
    }

    this.supabase = createClient(supabaseUrl, supabaseServiceKey);
  }

  async updateUserReward(userId: string, rewardAmount: number) {
    const { data: currentUser, error: userError } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', userId)
        .single();

    if (userError || !currentUser) {
        throw new Error(`User not found or error fetching user: ${userId}`);
    }
    // 여기에 보상 로직 추가
  }
  
  async addRewardHistory(userId: string, rewardAmount: number, transactionId: string) {
    const { error } = await this.supabase.from('star_candy_bonus_history').insert({
      type: 'AD',
      amount: rewardAmount,
      remain_amount: rewardAmount,
      user_id: userId,
      transaction_id: transactionId,
      expired_dt: getNextMonth15thAt9AM()
    });
    if (error) throw error;
  }

  async checkExistingTransaction(transactionId: string, tableName: string): Promise<boolean> {
    console.log(`[DB] ${tableName} 테이블에서 트랜잭션 ID(${transactionId}) 확인 중...`);
    const { data, error } = await this.supabase
      .from(tableName)
      .select('transaction_id')
      .eq('transaction_id', transactionId)
      .maybeSingle();
    
    if (error && error.code !== 'PGRST116') {
      console.error(`[DB] 트랜잭션 확인 중 오류 발생 (ID: ${transactionId}):`, error);
      throw error;
    }

    const exists = !!data;
    console.log(`[DB] 트랜잭션 ID(${transactionId}) 존재 여부: ${exists}`);
    return exists;
  }

  async checkUserExists(userId: string): Promise<boolean> {
    console.log(`[DB] user_profiles 테이블에서 사용자 ID(${userId}) 확인 중...`);
    const { data, error } = await this.supabase
      .from('user_profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') {
      console.error(`[DB] 사용자 확인 중 오류 발생 (ID: ${userId}):`, error);
      throw error;
    }
    
    const exists = !!data;
    console.log(`[DB] 사용자 ID(${userId}) 존재 여부: ${exists}`);
    return exists;
  }
  
  async executeTransaction(operations: () => Promise<any>) {
    // 이 함수는 현재 사용되지 않는 것으로 보임
  }
}
