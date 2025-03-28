declare module 'https://esm.sh/@supabase/supabase-js@2' {
  export function createClient(url: string, key: string): any;
}

declare module 'https://esm.sh/crypto-js' {
  export default class CryptoJS {
    static MD5(source: string): {
      toString(): string;
    };
  }
}

declare module 'https://deno.land/x/postgres@v0.17.0/mod.ts' {
  export class Pool {
    constructor(url: string | undefined, size: number, enabled: boolean);
    connect(): Promise<Connection>;
  }

  export interface Connection {
    queryObject(query: string, args?: any[]): Promise<QueryResult>;
    release(): void;
  }

  export interface QueryResult {
    rows: any[];
    rowCount: number;
    fields: any[];
    command: string;
  }
}

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
  }
  export function serve(handler: (req: Request) => Promise<Response>): void;
}

declare module 'crypto' {
  interface Window {
    crypto: Crypto;
  }

  interface Crypto {
    readonly subtle: SubtleCrypto;
  }

  interface SubtleCrypto {
    importKey(
      format: string,
      keyData: Uint8Array,
      algorithm: HmacKeyGenParams,
      extractable: boolean,
      keyUsages: KeyUsage[],
    ): Promise<CryptoKey>;
    verify(
      algorithm: string,
      key: CryptoKey,
      signature: Uint8Array,
      data: Uint8Array,
    ): Promise<boolean>;
  }

  interface HmacKeyGenParams {
    name: string;
    hash: string;
  }

  type KeyUsage = 'sign' | 'verify';

  interface CryptoKey {
    readonly type: 'secret' | 'private' | 'public';
    readonly extractable: boolean;
    readonly algorithm: HmacKeyGenParams;
    readonly usages: KeyUsage[];
  }
}

declare module 'http/server' {
  export function serve(handler: (req: Request) => Promise<Response>): void;
}

interface TransactionPangle {
  transaction_id: string;
  reward_type: string;
  reward_amount: number;
  signature: string;
  ad_network: string;
  platform: string;
  user_id: string;
}

declare module '@supabase/supabase-js' {
  export function createClient(url: string, key: string): any;
  interface Database {
    public: {
      Tables: {
        transaction_pangle: {
          Row: TransactionPangle;
          Insert: TransactionPangle;
          Update: Partial<TransactionPangle>;
        };
      };
    };
  }
}
