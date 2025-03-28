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
  abstract verify(params: AdParameters): Promise<any>;
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
}
