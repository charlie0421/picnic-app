import { Artist } from './artist';

// 투표 항목 인터페이스
export interface VoteItem {
  id?: string;
  artist_id: string;
  vote_total?: number;
  artist?: Artist;
  temp_id?: number | string;
  deleted?: boolean;
  is_existing?: boolean;
}
