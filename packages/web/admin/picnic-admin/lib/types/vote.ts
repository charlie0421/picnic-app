import { Artist } from './artist';

// 투표 항목 인터페이스
export interface VoteItem {
  id?: string;
  artist_id: string | number;
  vote_total?: number;
  artist?: Artist;
  temp_id?: number | string;
  deleted_at?: string | null;
  is_existing?: boolean;
}

export interface VotePick {
  id: number;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  vote_id: number | null;
  vote_item_id: number;
  user_id: string | null;
  amount: number | null;
}

export type VotePickCreateInput = Omit<VotePick, 'id' | 'created_at' | 'updated_at' | 'deleted_at'>;
export type VotePickUpdateInput = Partial<VotePickCreateInput>;
