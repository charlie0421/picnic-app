export interface FAQ {
  id: number;
  question: string;
  answer: string;
  category?: string;
  status: 'PUBLISHED' | 'DRAFT' | 'ARCHIVED';
  order_number: number;
  created_by: string;
  created_at: string;
  updated_at: string;
  created_by_user?: {
    email: string;
    user_metadata?: {
      name?: string;
    };
  };
} 