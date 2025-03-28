/// <reference path="../types.d.ts" />

import { createClient } from '@supabase/supabase-js';

export interface AdCallbackParams {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
}

export interface AdVerificationResult {
  isValid: boolean;
  error?: string;
}

interface AdParameters {
  user_id: string;
  reward_amount: number;
  reward_type: string;
  transaction_id: string;
  signature: string;
  platform: string;
  ad_network: string;
  app_key?: string;
  pub_key?: number;
  app_title?: string;
  menu_category?: string;
}

interface PincruxParameters {
  appkey: string; // 광고 코드(Pincrux 전용), 최대 40자리
  pubkey: number; // 매체 코드(Pincrux에서 발급), 6자리
  usrkey: string; // 매체사가 전달한 개인정보가 아닌 회원 유일 식별키
  app_title: string; // 매체사의 로그기록 또는 고객에게 노출할 광고 제목
  coin: string; // 매체사가 설정한 고객에게 지급할 포인트
  transid: string; // Pincrux 트랜잭션 키 값
  resign_flag: string; // 해당 광고는 중복 지급을 허용합니다 (y/n)
  commission: string; // 매체사가 정산 시 받는 매체비
  menu_category1: string; // 참여 광고 유형
}

interface PincruxResponse {
  code: string; // 응답 코드 (00: 성공, 01: 파라미터 부재, 05: 회원정보 불일치, 11: 이미 처리된 적립금, 99: 내부 오류)
}

export class AdService {
  private secretKey: string;
  private supabase: ReturnType<typeof createClient>;

  constructor(secretKey: string) {
    this.secretKey = secretKey;
    this.supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );
  }

  private getNextMonth15thAt9AM(): string {
    const now = new Date();
    const nextMonth = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      15,
      9,
      0,
      0,
    );
    return nextMonth.toISOString().slice(0, 19).replace('T', ' ');
  }

  private async processTransaction(params: AdParameters): Promise<void> {
    if (params.user_id === 'fakeForAdDebugLog') {
      console.log('디버깅 모드: 데이터베이스 업데이트를 건너뜁니다.');
      return;
    }

    switch (params.ad_network) {
      case 'admob':
        await this.processAdmobTransaction(params);
        break;
      case 'pangle':
        await this.processPangleTransaction(params);
        break;
      case 'tapjoy':
        await this.processTapjoyTransaction(params);
        break;
      case 'pincrux':
        await this.processPincruxTransaction(params);
        break;
      default:
        throw new Error(
          `지원하지 않는 광고 플랫폼입니다: ${params.ad_network}`,
        );
    }
  }

  private async processAdmobTransaction(params: AdParameters): Promise<void> {
    try {
      // 사용자 보상 업데이트
      const { data: currentUser } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', params.user_id)
        .single();

      if (!currentUser) throw new Error('User not found');

      const { error: updateError } = await this.supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: currentUser.star_candy_bonus + params.reward_amount,
        })
        .eq('id', params.user_id);

      if (updateError) throw updateError;

      // 보상 히스토리 추가
      const { error: historyError } = await this.supabase
        .from('star_candy_bonus_history')
        .insert({
          type: 'AD',
          amount: params.reward_amount,
          remain_amount: params.reward_amount,
          user_id: params.user_id,
          transaction_id: params.transaction_id,
          expired_dt: this.getNextMonth15thAt9AM(),
        });

      if (historyError) throw historyError;

      // AdMob 트랜잭션 기록
      const { error: transactionError } = await this.supabase
        .from('transaction_admob')
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
    } catch (error) {
      console.error('AdMob transaction failed:', error);
      throw error;
    }
  }

  private async processPangleTransaction(params: AdParameters): Promise<void> {
    try {
      // 사용자 보상 업데이트
      const { data: currentUser } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', params.user_id)
        .single();

      if (!currentUser) throw new Error('User not found');

      const { error: updateError } = await this.supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: currentUser.star_candy_bonus + params.reward_amount,
        })
        .eq('id', params.user_id);

      if (updateError) throw updateError;

      // 보상 히스토리 추가
      const { error: historyError } = await this.supabase
        .from('star_candy_bonus_history')
        .insert({
          type: 'AD',
          amount: params.reward_amount,
          remain_amount: params.reward_amount,
          user_id: params.user_id,
          transaction_id: params.transaction_id,
          expired_dt: this.getNextMonth15thAt9AM(),
        });

      if (historyError) throw historyError;

      // Pangle 트랜잭션 기록
      const { error: transactionError } = await this.supabase
        .from('transaction_pangle')
        .insert({
          transaction_id: params.transaction_id,
          reward_type: params.reward_type,
          reward_amount: params.reward_amount,
          signature: params.signature,
          ad_network: params.ad_network,
          platform: params.platform,
          user_id: params.user_id,
        });

      if (transactionError) throw transactionError;
    } catch (error) {
      console.error('Pangle transaction failed:', error);
      throw error;
    }
  }

  private async processTapjoyTransaction(params: AdParameters): Promise<void> {
    try {
      // 사용자 보상 업데이트
      const { data: currentUser } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', params.user_id)
        .single();

      if (!currentUser) throw new Error('User not found');

      const { error: updateError } = await this.supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: currentUser.star_candy_bonus + params.reward_amount,
        })
        .eq('id', params.user_id);

      if (updateError) throw updateError;

      // 보상 히스토리 추가
      const { error: historyError } = await this.supabase
        .from('star_candy_bonus_history')
        .insert({
          type: 'AD',
          amount: params.reward_amount,
          remain_amount: params.reward_amount,
          user_id: params.user_id,
          transaction_id: params.transaction_id,
          expired_dt: this.getNextMonth15thAt9AM(),
        });

      if (historyError) throw historyError;

      // Tapjoy 트랜잭션 기록
      const { error: transactionError } = await this.supabase
        .from('transaction_tapjoy')
        .insert({
          transaction_id: params.transaction_id,
          reward_type: params.reward_type,
          reward_amount: params.reward_amount,
          signature: params.signature,
          ad_network: params.ad_network,
          platform: params.platform,
          user_id: params.user_id,
        });

      if (transactionError) throw transactionError;
    } catch (error) {
      console.error('Tapjoy transaction failed:', error);
      throw error;
    }
  }

  private async processPincruxTransaction(params: AdParameters): Promise<void> {
    try {
      // 사용자 보상 업데이트
      const { data: currentUser } = await this.supabase
        .from('user_profiles')
        .select('star_candy_bonus')
        .eq('id', params.user_id)
        .single();

      if (!currentUser) throw new Error('User not found');

      const { error: updateError } = await this.supabase
        .from('user_profiles')
        .update({
          star_candy_bonus: currentUser.star_candy_bonus + params.reward_amount,
        })
        .eq('id', params.user_id);

      if (updateError) throw updateError;

      // 보상 히스토리 추가
      const { error: historyError } = await this.supabase
        .from('star_candy_bonus_history')
        .insert({
          type: 'AD',
          amount: params.reward_amount,
          remain_amount: params.reward_amount,
          user_id: params.user_id,
          transaction_id: params.transaction_id,
          expired_dt: this.getNextMonth15thAt9AM(),
        });

      if (historyError) throw historyError;

      // Pincrux 트랜잭션 기록
      const { error: transactionError } = await this.supabase
        .from('transaction_pincrux')
        .insert({
          transaction_id: params.transaction_id,
          reward_type: params.reward_type,
          reward_amount: params.reward_amount,
          app_key: params.app_key,
          pub_key: params.pub_key,
          usr_key: params.user_id,
          app_title: params.app_title,
          coin: String(params.reward_amount),
          resign_flag: 'n',
          menu_category1: params.menu_category || '1',
          user_id: params.user_id,
        });

      if (transactionError) throw transactionError;
    } catch (error) {
      console.error('Pincrux transaction failed:', error);
      throw error;
    }
  }

  // AdMob 파라미터 추출
  extractAdmobParameters(url: URL): AdParameters {
    const params = url.searchParams;
    const user_id = params.get('user_id') || '';
    const reward_amount = parseInt(params.get('reward_amount') || '0', 10);
    const reward_type = params.get('reward_type') || 'free_charge_station';
    const transaction_id = params.get('transaction_id') || '';
    const signature = params.get('signature') || '';
    const platform = params.get('platform') || '';

    return {
      user_id,
      reward_amount,
      reward_type,
      transaction_id,
      signature,
      platform,
      ad_network: 'admob',
    };
  }

  // Pangle 파라미터 추출
  extractPangleParameters(url: URL): AdParameters {
    const params = url.searchParams;
    const trans_id = params.get('trans_id') || '';
    const reward_amount = parseInt(params.get('reward_amount') ?? '0', 10);
    const extra = params.get('extra') || '';
    const sign = params.get('sign') || '';
    let user_id = params.get('user_id') || '';
    let reward_type = 'free_charge_station';
    let platform = '';

    if (extra) {
      const extraArray = extra.split(',');
      user_id = extraArray[0] || user_id;
      platform = extraArray[1] || platform;

      try {
        const parsedData = JSON.parse(extra);
        if (user_id === '') {
          user_id = parsedData.user_id || '';
        }
        reward_type = parsedData.reward_type || reward_type;
      } catch (error) {
        console.log(`JSON 파싱 실패, extra: ${extra}. 기본값 사용, ${error}`);
      }
    }

    return {
      user_id,
      reward_amount,
      reward_type,
      transaction_id: trans_id,
      signature: sign,
      platform,
      ad_network: 'pangle',
    };
  }

  // Tapjoy 파라미터 추출
  extractTapjoyParameters(url: URL): AdParameters {
    const params = url.searchParams;
    const platform = params.get('platform') || '';
    const currency = parseInt(params.get('currency') || '0', 10);
    const snuid = params.get('snuid') || '';
    const id = params.get('id') || '';
    const verifier = params.get('verifier') || '';

    return {
      user_id: snuid,
      reward_amount: currency,
      reward_type: 'MISSION',
      transaction_id: id,
      signature: verifier,
      platform,
      ad_network: 'tapjoy',
    };
  }

  // Pincrux 파라미터 추출
  extractPincruxParameters(url: URL): AdParameters {
    const params = url.searchParams;
    const app_key = params.get('appkey') || '';
    const pub_key = parseInt(params.get('pubkey') || '0', 10);
    const usr_key = params.get('usrkey') || '';
    const app_title = params.get('app_title') || '';
    const coin = params.get('coin') || '0';
    const transid = params.get('transid') || '';
    const menu_category = params.get('menu_category1') || '1';

    return {
      user_id: usr_key,
      reward_amount: parseInt(coin, 10),
      reward_type: 'free_charge_station',
      transaction_id: transid,
      signature: app_key, // Pincrux는 별도의 signature가 없으므로 app_key를 사용
      platform: 'pincrux',
      ad_network: 'pincrux',
      app_key,
      pub_key,
      app_title,
      menu_category,
    };
  }

  // AdMob 파라미터 검증
  validateAdmobParameters(params: AdParameters): boolean {
    const { user_id, reward_amount, reward_type, transaction_id, signature } =
      params;
    return !!(
      user_id &&
      reward_amount &&
      reward_type &&
      transaction_id &&
      signature
    );
  }

  // Pangle 파라미터 검증
  validatePangleParameters(params: AdParameters): boolean {
    const { user_id, reward_amount, reward_type, transaction_id, signature } =
      params;
    return !!(
      user_id &&
      reward_amount &&
      reward_type &&
      transaction_id &&
      signature
    );
  }

  // Tapjoy 파라미터 검증
  validateTapjoyParameters(params: AdParameters): boolean {
    const { platform, reward_amount, user_id } = params;
    return !!(platform && reward_amount && user_id);
  }

  // Pincrux 파라미터 검증
  validatePincruxParameters(params: AdParameters): boolean {
    const { user_id, reward_amount, transaction_id, app_key, pub_key } = params;
    return !!(user_id && reward_amount && transaction_id && app_key && pub_key);
  }

  async verifyAdCallback(params: AdParameters): Promise<AdVerificationResult> {
    try {
      await this.processTransaction(params);
      return { isValid: true };
    } catch (error) {
      console.error('Error processing ad callback:', error);
      return {
        isValid: false,
        error:
          error instanceof Error
            ? error.message
            : '알 수 없는 오류가 발생했습니다.',
      };
    }
  }

  async verifyTapjoySignature(
    transaction_id: string,
    user_id: string,
    reward_amount: number,
    signature: string,
  ): Promise<boolean> {
    try {
      if (!this.secretKey) {
        throw new Error('Secret key is missing');
      }

      const encoder = new TextEncoder();
      const keyData = encoder.encode(this.secretKey);
      const data = encoder.encode(
        `${transaction_id}${user_id}${reward_amount}`,
      );

      const key = await crypto.subtle.importKey(
        'raw',
        keyData,
        {
          name: 'HMAC',
          hash: 'SHA-256',
        },
        false,
        ['sign', 'verify'],
      );

      const signatureArray = Uint8Array.from(
        atob(signature.replace(/-/g, '+').replace(/_/g, '/')),
        (c) => c.charCodeAt(0),
      );
      return await crypto.subtle.verify('HMAC', key, signatureArray, data);
    } catch (error) {
      console.error('Error during signature verification:', error);
      return false;
    }
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
}
