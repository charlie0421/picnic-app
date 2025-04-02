// 아티스트 인터페이스
export interface Artist {
  id: string;
  name?: {
    ko?: string;
    en?: string;
    ja?: string;
    zh?: string;
  };
  image?: string;
  birth_date?: string;
  yy?: number;
  mm?: number;
  dd?: number;
  artist_group?: {
    id: number;
    name?: {
      ko?: string;
      en?: string;
      ja?: string;
      zh?: string;
    };
    image?: string;
    debut_yy?: number;
    debut_mm?: number;
    debut_dd?: number;
  };
}

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
