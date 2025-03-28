import { createClient } from '@supabase/supabase-js';
import { AdParameters } from './interfaces/ad-parameters.ts';
import { getNextMonth15thAt9AM } from './utils/date.ts';

export interface BaseAdCallbackResponse {
  status: number;
}

export interface PangleAdCallbackResponse extends BaseAdCallbackResponse {
  body: {
    isValid: boolean;
    error?: string;
  };
}

export interface PincruxAdCallbackResponse extends BaseAdCallbackResponse {
  body: {
    code: string;
    error?: string;
  };
}

export interface TapjoyAdCallbackResponse extends BaseAdCallbackResponse {
  body: {
    success: boolean;
    error?: string;
  };
}

export interface AdMobAdCallbackResponse extends BaseAdCallbackResponse {
  body: {
    success: boolean;
    error?: string;
  };
}

export interface DefaultAdCallbackResponse extends BaseAdCallbackResponse {}

export abstract class BaseAdService {
  protected supabase: ReturnType<typeof createClient>;
  protected secretKey: string;

  constructor(secretKey: string) {
    this.secretKey = secretKey;
    this.supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
  }

  abstract validateParameters(params: AdParameters): boolean;
  abstract extractParameters(url: URL): AdParameters;
  abstract verify(
    params: AdParameters,
  ): Promise<{ isValid: boolean; error?: string }>;
  abstract processTransaction(params: AdParameters): Promise<void>;
  abstract getResponseCode(error?: Error): string;
  abstract handleCallback(
    params: AdParameters,
  ): Promise<
    | PangleAdCallbackResponse
    | PincruxAdCallbackResponse
    | TapjoyAdCallbackResponse
    | AdMobAdCallbackResponse
  >;

  protected async updateUserReward(
    userId: string,
    rewardAmount: number,
  ): Promise<void> {
    const { data: currentUser } = await this.supabase
      .from('user_profiles')
      .select('star_candy_bonus')
      .eq('id', userId)
      .single();

    if (!currentUser) throw new Error('User not found');

    const { error } = await this.supabase
      .from('user_profiles')
      .update({
        star_candy_bonus: currentUser.star_candy_bonus + rewardAmount,
      })
      .eq('id', userId);

    if (error) throw error;
  }

  protected async addRewardHistory(
    userId: string,
    rewardAmount: number,
    transactionId: string,
  ): Promise<void> {
    const { error } = await this.supabase
      .from('star_candy_bonus_history')
      .insert({
        type: 'AD',
        amount: rewardAmount,
        remain_amount: rewardAmount,
        user_id: userId,
        transaction_id: transactionId,
        expired_dt: getNextMonth15thAt9AM(),
      });

    if (error) throw error;
  }

  async checkExistingTransaction(
    transactionId: string,
    tableName: string,
  ): Promise<boolean> {
    const { data } = await this.supabase
      .from(tableName)
      .select('transaction_id')
      .eq('transaction_id', transactionId)
      .single();
    return !!data;
  }

  async checkUserExists(userId: string): Promise<boolean> {
    const { data } = await this.supabase
      .from('user_profiles')
      .select('id')
      .eq('id', userId)
      .single();
    return !!data;
  }

  protected async executeTransaction<T>(
    operations: () => Promise<T>,
  ): Promise<T> {
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

  protected async processAdTransaction(
    params: AdParameters,
    platform: string,
  ): Promise<void> {
    await this.executeTransaction(async () => {
      // 사용자 보너스 업데이트
      const { data: currentUser, error: userError } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', params.user_id)
        .single();

      if (userError) throw userError;
      if (!currentUser) throw new Error('User not found');

      const { error: updateError } = await this.supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: currentUser.star_candy_bonus + params.reward_amount,
        })
        .eq('id', params.user_id);

      if (updateError) throw updateError;

      // 보너스 히스토리 추가
      const { error: historyError } = await this.supabase
        .from('star_candy_bonus_history')
        .insert({
          type: 'AD',
          amount: params.reward_amount,
          remain_amount: params.reward_amount,
          user_id: params.user_id,
          transaction_id: params.transaction_id,
          expired_dt: getNextMonth15thAt9AM(),
        });

      if (historyError) throw historyError;

      // 플랫폼별 트랜잭션 기록 추가
      const { error: transactionError } = await this.supabase
        .from(`transaction_${platform}`)
        .insert({
          transaction_id: params.transaction_id,
          reward_type: params.reward_type,
          reward_amount: params.reward_amount,
          signature: params.signature,
          ad_network: params.ad_network,
          key_id: params.transaction_id,
          user_id: params.user_id,
        });

      if (transactionError) throw transactionError;
    });
  }
}
