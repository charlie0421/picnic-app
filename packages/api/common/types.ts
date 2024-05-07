type PortOnePaymentMethod = 'samsung' | //삼성페이
  'card' | //신용카드
  'trans' | //계좌이체
  'vbank' | //가상계좌
  'phone' | //휴대폰
  'cultureland' | //문화상품권
  'smartculture' | //스마트문상
  'booknlife' | //도서문화상품권
  'happymoney' | //해피머니
  'point' | //포인트
  'ssgpay' | //SSGPAY
  'lpay' | //LPAY
  'payco' | //페이코
  'kakaopay' | //카카오페이
  'tosspay' | //토스
  'naverpay'; //네이버페이

type PortOnePaymentChannel = 'pc' | // (인증방식)PC결제
  'mobile' | // (인증방식)모바일결제
  'app'; // 정기결제 또는 비인증 결제

type PortOnePaymentStatus = 'ready' | //미결제
  'paid' | //결제완료
  'cancelled' | //결제취소
  'failed'; //결제실패

type PortOnePaymentCustomerUidUsage = 'null' | //일반결제
  'issue' | //빌링키 발급
  'payment' | //결제
  'payment.scheduled'; //예약결제

export interface PortOnePaymentResponse {
  code: number;
  message: string | null;
  response: {
    imp_uid: string;
    merchant_uid: string;
    pay_method: PortOnePaymentMethod;
    channel: PortOnePaymentChannel;
    pg_provider: string;
    emb_pg_provider: string;
    pg_tid: string;
    pg_id: string;
    escrow: true;
    apply_num: string;
    bank_code: string;
    bank_name: string;
    card_code: string;
    card_name: string;
    card_quota: number;
    card_number: string;
    card_type: null;
    vbank_code: string;
    vbank_name: string;
    vbank_num: string;
    vbank_holder: string;
    vbank_date: number;
    vbank_issued_at: number;
    name: string;
    amount: number;
    cancel_amount: number;
    currency: string;
    buyer_name: string;
    buyer_email: string;
    buyer_tel: string;
    buyer_addr: string;
    buyer_postcode: string;
    custom_data: string;
    user_agent: string;
    status: PortOnePaymentStatus;
    started_at: 0;
    paid_at: 0;
    failed_at: 0;
    cancelled_at: 0;
    fail_reason: string;
    cancel_reason: string;
    receipt_url: string;
    cancel_history?: {
      pg_tid: string;
      amount: 0;
      cancelled_at: 0;
      reason: string;
      receipt_url: string;
    }[];
    cancel_receipt_urls?: string[];
    cash_receipt_issued: true;
    customer_uid: string;
    customer_uid_usage: PortOnePaymentCustomerUidUsage;
  };
}

export interface PortOneAccessTokenResponse {
  code: number;
  message: null;
  response: {
    access_token: string;
    now: number; // unix timestamp
    expired_at: number; // unix timestamp
  };
}

export type ArticleCategory = 'all' | 'recruiting' | 'qna' | 'share' | 'everyday_life' | undefined;

export type ArticleSort = 'latest' | 'popular' | 'comment';

export type AttachmentStatusType = 'add' | 'remove' | 'keep';

export type EntityType = 'article' | 'comment' | 'club' | 'stadium' | 'stadium_floor';
