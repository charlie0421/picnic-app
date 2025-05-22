export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      artist: {
        Row: {
          id: number
          name: string | { [lang: string]: string }
          image: string | null
          artist_group_id: number | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          name: string | { [lang: string]: string }
          image?: string | null
          artist_group_id?: number | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          name?: string | { [lang: string]: string }
          image?: string | null
          artist_group_id?: number | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "artist_artist_group_id_fkey"
            columns: ["artist_group_id"]
            referencedRelation: "artist_group"
            referencedColumns: ["id"]
          }
        ]
      }
      artist_group: {
        Row: {
          id: number
          name: string | { [lang: string]: string }
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          name: string | { [lang: string]: string }
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          name?: string | { [lang: string]: string }
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          id: string
          email: string | null
          nickname: string | null
          avatar_url: string | null
          bio: string | null
          is_admin: boolean
          birth_date: string | null
          birth_time: string | null
          gender: string | null
          open_birth_date: boolean
          open_birth_time: boolean
          open_gender: boolean
          open_ages: boolean
          star_candy: number
          star_candy_bonus: number
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id: string
          email?: string | null
          nickname?: string | null
          avatar_url?: string | null
          bio?: string | null
          is_admin?: boolean
          birth_date?: string | null
          birth_time?: string | null
          gender?: string | null
          open_birth_date?: boolean
          open_birth_time?: boolean
          open_gender?: boolean
          open_ages?: boolean
          star_candy?: number
          star_candy_bonus?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          email?: string | null
          nickname?: string | null
          avatar_url?: string | null
          bio?: string | null
          is_admin?: boolean
          birth_date?: string | null
          birth_time?: string | null
          gender?: string | null
          open_birth_date?: boolean
          open_birth_time?: boolean
          open_gender?: boolean
          open_ages?: boolean
          star_candy?: number
          star_candy_bonus?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_id_fkey"
            columns: ["id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      vote: {
        Row: {
          id: number
          title: string | { [lang: string]: string }
          vote_category: string
          vote_sub_category: string | null
          vote_content: string | null
          main_image: string | null
          result_image: string | null
          wait_image: string | null
          start_at: string
          stop_at: string
          visible_at: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          title: string | { [lang: string]: string }
          vote_category: string
          vote_sub_category?: string | null
          vote_content?: string | null
          main_image?: string | null
          result_image?: string | null
          wait_image?: string | null
          start_at: string
          stop_at: string
          visible_at?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          title?: string | { [lang: string]: string }
          vote_category?: string
          vote_sub_category?: string | null
          vote_content?: string | null
          main_image?: string | null
          result_image?: string | null
          wait_image?: string | null
          start_at?: string
          stop_at?: string
          visible_at?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
      vote_item: {
        Row: {
          id: number
          vote_id: number
          artist_id: number | null
          group_id: number | null
          vote_total: number
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          vote_id: number
          artist_id?: number | null
          group_id?: number | null
          vote_total?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          vote_id?: number
          artist_id?: number | null
          group_id?: number | null
          vote_total?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "vote_item_artist_id_fkey"
            columns: ["artist_id"]
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_item_group_id_fkey"
            columns: ["group_id"]
            referencedRelation: "artist_group"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_item_vote_id_fkey"
            columns: ["vote_id"]
            referencedRelation: "vote"
            referencedColumns: ["id"]
          }
        ]
      }
      vote_reward: {
        Row: {
          vote_id: number
          reward_id: number
        }
        Insert: {
          vote_id: number
          reward_id: number
        }
        Update: {
          vote_id?: number
          reward_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "vote_reward_reward_id_fkey"
            columns: ["reward_id"]
            referencedRelation: "reward"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_reward_vote_id_fkey"
            columns: ["vote_id"]
            referencedRelation: "vote"
            referencedColumns: ["id"]
          }
        ]
      }
      reward: {
        Row: {
          id: number
          name: string | { [lang: string]: string }
          description: string | { [lang: string]: string } | null
          image: string | null
          price: number | null
          order: number
          overview_images: string[] | null
          location_images: string[] | null
          size_guide: Json | null
          size_guide_images: string[] | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          name: string | { [lang: string]: string }
          description?: string | { [lang: string]: string } | null
          image?: string | null
          price?: number | null
          order?: number
          overview_images?: string[] | null
          location_images?: string[] | null
          size_guide?: Json | null
          size_guide_images?: string[] | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          name?: string | { [lang: string]: string }
          description?: string | { [lang: string]: string } | null
          image?: string | null
          price?: number | null
          order?: number
          overview_images?: string[] | null
          location_images?: string[] | null
          size_guide?: Json | null
          size_guide_images?: string[] | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
      media: {
        Row: {
          id: number
          title: string | { [lang: string]: string }
          thumbnail_url: string | null
          video_url: string | null
          video_id: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          title: string | { [lang: string]: string }
          thumbnail_url?: string | null
          video_url?: string | null
          video_id?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          title?: string | { [lang: string]: string }
          thumbnail_url?: string | null
          video_url?: string | null
          video_id?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
      banner: {
        Row: {
          id: number
          location: string
          image_url: string
          link_url: string | null
          start_at: string
          end_at: string | null
          celeb_id: number | null
          order: number
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: number
          location: string
          image_url: string
          link_url?: string | null
          start_at: string
          end_at?: string | null
          celeb_id?: number | null
          order?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: number
          location?: string
          image_url?: string
          link_url?: string | null
          start_at?: string
          end_at?: string | null
          celeb_id?: number | null
          order?: number
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_user_vote: {
        Args: {
          p_vote_id: string
          p_user_id: string
        }
        Returns: UserVote
      }
      add_user_vote: {
        Args: {
          p_user_id: string
          p_vote_id: string
          p_vote_item_id: string
        }
        Returns: undefined
      }
      increment_vote: {
        Args: {
          vote_item_id: string
        }
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

/**
 * Supabase 테이블 인터페이스
 * 
 * 이 파일은 Supabase 테이블 중 기본 인터페이스에 정의되지 않은 
 * 테이블에 대한 타입 정의를 포함합니다.
 */

// 사용자 투표 관련 인터페이스
export interface UserVote {
  id: string;
  user_id: string;
  vote_id: string;
  vote_item_id: string;
  created_at: string;
}

// Supabase RPC 함수 응답 타입
export interface SupabaseRpcResponse {
  data: any;
  error: Error | null;
}
