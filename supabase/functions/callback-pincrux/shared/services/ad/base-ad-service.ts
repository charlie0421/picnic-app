import { createClient } from '@supabase/supabase-js';
import { getNextMonth15thAt9AM } from './utils/date.ts';
export interface AdRewardCredit {
  sourceKey: 'pincrux_reward';
  operationKey: string;
  userId: string;
  rewardAmount: number;
  referenceType: string;
  referenceId: string;
  writer: string;
  bonusExpiresAt: string;
}
export class BaseAdService {
  supabase;
  secretKey;
  constructor(secretKey){
    this.secretKey = secretKey;
    this.supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
  }
  async updateUserReward(userId, rewardAmount) {
    const { data: currentUser } = await this.supabase.from('user_profiles').select('star_candy_bonus').eq('id', userId).single();
    if (!currentUser) throw new Error('User not found');
  }
  async addRewardHistory(userId, rewardAmount, transactionId) {
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
  async creditBonus(credit: AdRewardCredit) {
    const { error } = await this.supabase.rpc('wallet_credit_bonus', {
      p_user_id: credit.userId,
      p_source_key: credit.sourceKey,
      p_operation_key: credit.operationKey,
      p_bonus_amount: credit.rewardAmount,
      p_bonus_expires_at: credit.bonusExpiresAt,
      p_reason: 'AD',
      p_reference_type: credit.referenceType,
      p_reference_id: credit.referenceId,
      p_metadata: { writer: credit.writer }
    });
    if (error) throw error;
  }
  async checkExistingTransaction(transactionId, tableName) {
    const { data } = await this.supabase.from(tableName).select('transaction_id').eq('transaction_id', transactionId).single();
    return !!data;
  }
  async checkUserExists(userId) {
    const { data } = await this.supabase.from('user_profiles').select('id').eq('id', userId).single();
    return !!data;
  }
  async executeTransaction(operations) {
    const { error } = await this.supabase.rpc('begin_transaction');
    if (error) throw error;
    try {
      const result = await operations();
      await this.supabase.rpc('commit_transaction');
      return result;
    } catch (error) {
      await this.supabase.rpc('rollback_transaction');
      throw error;
    }
  }
}
