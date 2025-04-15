export interface QnA {
  id: number;
  title: string;
  question: string;
  answer?: string;
  status: 'PENDING' | 'ANSWERED' | 'ARCHIVED';
  is_private: boolean;
  created_by: string;
  answered_by?: string;
  answered_at?: string;
  created_at: string;
  updated_at: string;
  created_by_user?: {
    email: string;
    user_metadata?: {
      name?: string;
    };
  };
  answered_by_user?: {
    email: string;
    user_metadata?: {
      name?: string;
    };
  };
} 