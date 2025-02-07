// 공통 타입
type Timestamp = string;

// 기본 모델 타입 (created_at, updated_at, deleted_at)
interface BaseModel {
  created_at: Timestamp;
  updated_at: Timestamp;
  deleted_at?: Timestamp;
}

// JSON 이름 타입 (다국어 지원)
interface LocalizedName {
  ko?: string;
  en?: string;
  ja?: string;
  zh?: string;
}

export interface ArtistGroup extends BaseModel {
  id: number;
  name: LocalizedName;
  image: string;
  debut_yy?: number;
  debut_mm?: number;
  debut_dd?: number;
}

export interface Artist extends BaseModel {
  id: number;
  name: LocalizedName;
  yy?: number;
  mm?: number;
  dd?: number;
  gender?: string;
  group_id: number;
  artist_group: ArtistGroup;
  image?: string;
  birth_date?: string;
  debut_yy?: number;
  debut_mm?: number;
  debut_dd?: number;
}

export interface VoteItem extends BaseModel {
  id: number;
  vote_total: number;
  artist: Artist;
}

export type VoteData = {
  voteInfo: {
    id: string;
    vote_category: string;
    title: LocalizedName;
    start_at: string;
    stop_at: string;
  } | null;
  topThree: VoteItem[] | null;
};
