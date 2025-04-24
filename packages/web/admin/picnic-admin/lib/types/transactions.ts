export type AdSource = 'admob' | 'pangle' | 'pincrux' | 'tapjoy' | 'unity';

export interface Transaction {
  source: AdSource;
  transaction_id: string;
  user_id: string | null;
  reward_type: string;
  reward_amount: number;
  ad_network: string | null;
  platform: string | null;
  reward_name: string | null;
  commission: number | null;
  created_at: string;
} 