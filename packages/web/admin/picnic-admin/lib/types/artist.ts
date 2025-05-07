// // DB 스키마 기반 아티스트 인터페이스
// export interface ArtistSchema {
//   id: number;
//   created_at: string;
//   updated_at: string;
//   deleted_at: string | null;
//   name: Record<string, string>; // JSON 타입
//   yy: number | null;
//   mm: number | null;
//   dd: number | null;
//   gender: string | null;
//   artist_group_id: number;
//   image: string | null;
//   birth_date: string | null;
//   debut_yy: number | null;
//   debut_mm: number | null;
//   debut_dd: number | null;
//   artist_group?: ArtistGroupSchema;
// }

// // DB 스키마 기반 아티스트 그룹 인터페이스
// export interface ArtistGroupSchema {
//   id: number;
//   created_at: string;
//   updated_at: string;
//   deleted_at: string | null;
//   name: Record<string, string>; // JSON 타입
//   image: string;
//   debut_yy: number | null;
//   debut_mm: number | null;
//   debut_dd: number | null;
//   artists?: ArtistSchema[];
// }

// 애플리케이션에서 사용할 통합 아티스트 인터페이스
export interface Artist {
  id: string | number;
  name?: Record<string, string>;
  image?: string | null;
  birth_date?: string | null;
  yy?: number | null;
  mm?: number | null;
  dd?: number | null;
  gender?: string | null;
  artist_group_id?: number;
  group_id?: number;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string | null;
  debut_date?: string | null;
  debut_yy?: number | null;
  debut_mm?: number | null;
  debut_dd?: number | null;
  artist_group?: ArtistGroup;
}

// 애플리케이션에서 사용할 통합 아티스트 그룹 인터페이스
export interface ArtistGroup {
  id: string;
  name: {
    ko: string;
    en: string;
    ja: string;
    zh: string;
    id: string;
  };
  image?: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
  debut_date?: string | null;
  debut_yy?: number | null;
  debut_mm?: number | null;
  debut_dd?: number | null;
  artists?: Artist[];
}
