import { Board } from "./board";
import { UserProfile } from "./user_profiles";

export interface Post {
  post_id: string;
  user_id: string;
  board_id: string | null;
  title: string;
  content: any[];
  created_at: string;
  view_count: number;
  is_hidden: boolean;
  updated_at: string;
  is_anonymous: boolean;
  attachments: string[];
  reply_count: number;
  deleted_at: string | null;
  is_temporary: boolean;
  boards: Board;
  user_profiles: UserProfile;
}

export type PostCreateInput = Omit<
  Post,
  'post_id' | 'created_at' | 'updated_at' | 'view_count' | 'reply_count'
>;
export type PostUpdateInput = Partial<PostCreateInput>;
