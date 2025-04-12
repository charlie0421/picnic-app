export interface Receipt {
  id: number;
  receipt_data: string;
  status: string;
  platform: string;
  created_at: string;
  user_id?: string;
  product_id?: string;
  environment?: string;
  verification_data?: any; // jsonb 타입
  receipt_hash?: string;
}

export const RECEIPT_STATUS = {
  VALID: 'valid',
  INVALID: 'invalid',
  PENDING: 'pending',
};

export const RECEIPT_PLATFORM = {
  IOS: 'ios',
  ANDROID: 'android',
};

export const RECEIPT_ENVIRONMENT = {
  PRODUCTION: 'production',
  SANDBOX: 'sandbox',
}; 