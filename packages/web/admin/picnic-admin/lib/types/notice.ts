export interface Notice {
  id: number;
  title: string;
  content: string;
  status: 'PUBLISHED' | 'DRAFT' | 'ARCHIVED';
  is_pinned: boolean;
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