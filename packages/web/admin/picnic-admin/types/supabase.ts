export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      activities: {
        Row: {
          activity_type: string
          description: string
          details: Json | null
          id: number
          ip_address: string | null
          resource_id: string | null
          resource_type: string
          timestamp: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          activity_type: string
          description: string
          details?: Json | null
          id?: number
          ip_address?: string | null
          resource_id?: string | null
          resource_type: string
          timestamp?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          activity_type?: string
          description?: string
          details?: Json | null
          id?: number
          ip_address?: string | null
          resource_id?: string | null
          resource_type?: string
          timestamp?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      admin_permissions: {
        Row: {
          action: string
          created_at: string | null
          description: string | null
          id: string
          resource: string
          updated_at: string | null
        }
        Insert: {
          action: string
          created_at?: string | null
          description?: string | null
          id?: string
          resource: string
          updated_at?: string | null
        }
        Update: {
          action?: string
          created_at?: string | null
          description?: string | null
          id?: string
          resource?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      admin_role_permissions: {
        Row: {
          created_at: string | null
          id: string
          permission_id: string
          role_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          permission_id: string
          role_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          permission_id?: string
          role_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "admin_permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_roles: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      admin_user_roles: {
        Row: {
          created_at: string | null
          id: string
          role_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          role_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          role_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "admin_roles"
            referencedColumns: ["id"]
          },
        ]
      }
      album: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          id: number | null
          title: string | null
          updated_at: string | null
          user_id: number | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          title?: string | null
          updated_at?: string | null
          user_id?: number | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          title?: string | null
          updated_at?: string | null
          user_id?: number | null
        }
        Relationships: []
      }
      album_image: {
        Row: {
          album_id: number | null
          image_id: number | null
        }
        Insert: {
          album_id?: number | null
          image_id?: number | null
        }
        Update: {
          album_id?: number | null
          image_id?: number | null
        }
        Relationships: []
      }
      album_image_user: {
        Row: {
          image_id: number | null
          user_id: number | null
        }
        Insert: {
          image_id?: number | null
          user_id?: number | null
        }
        Update: {
          image_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      app_splash: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          duration: number | null
          end_at: string | null
          id: number
          image: Json | null
          start_at: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          duration?: number | null
          end_at?: string | null
          id?: number
          image?: Json | null
          start_at?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          duration?: number | null
          end_at?: string | null
          id?: number
          image?: Json | null
          start_at?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      article: {
        Row: {
          comment_count: number | null
          content: string | null
          created_at: string | null
          deleted_at: string | null
          gallery_id: number
          id: number
          title_en: string | null
          title_ko: string | null
          updated_at: string | null
        }
        Insert: {
          comment_count?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          gallery_id: number
          id?: number
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string | null
        }
        Update: {
          comment_count?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          gallery_id?: number
          id?: number
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "article_gallery_id_fkey"
            columns: ["gallery_id"]
            isOneToOne: false
            referencedRelation: "gallery"
            referencedColumns: ["id"]
          },
        ]
      }
      article_comment: {
        Row: {
          article_id: number | null
          childrencount: number | null
          content: string | null
          created_at: string | null
          deleted_at: string | null
          id: number | null
          likes: number | null
          parent_id: number | null
          updated_at: string | null
          user_id: number | null
        }
        Insert: {
          article_id?: number | null
          childrencount?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          likes?: number | null
          parent_id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Update: {
          article_id?: number | null
          childrencount?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          likes?: number | null
          parent_id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Relationships: []
      }
      article_comment_like: {
        Row: {
          comment_id: number | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      article_comment_report: {
        Row: {
          comment_id: number | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      article_image: {
        Row: {
          article_id: number
          created_at: string | null
          deleted_at: string | null
          id: number
          image: string | null
          order: number | null
          title_en: string | null
          title_ko: string | null
          updated_at: string | null
        }
        Insert: {
          article_id: number
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          image?: string | null
          order?: number | null
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string | null
        }
        Update: {
          article_id?: number
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          image?: string | null
          order?: number | null
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "article_image_article_id_fkey"
            columns: ["article_id"]
            isOneToOne: false
            referencedRelation: "article"
            referencedColumns: ["id"]
          },
        ]
      }
      article_image_user: {
        Row: {
          image_id: number
          user_id: string
        }
        Insert: {
          image_id: number
          user_id: string
        }
        Update: {
          image_id?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "article_image_user_image_id_fkey"
            columns: ["image_id"]
            isOneToOne: false
            referencedRelation: "article_image"
            referencedColumns: ["id"]
          },
        ]
      }
      artist: {
        Row: {
          birth_date: string | null
          created_at: string
          dd: number | null
          debut_date: string | null
          debut_dd: number | null
          debut_mm: number | null
          debut_yy: number | null
          deleted_at: string | null
          gender: string | null
          group_id: number | null
          id: number
          image: string | null
          is_kpop: boolean
          is_musical: boolean
          is_solo: boolean
          mm: number | null
          name: Json | null
          updated_at: string
          yy: number | null
        }
        Insert: {
          birth_date?: string | null
          created_at?: string
          dd?: number | null
          debut_date?: string | null
          debut_dd?: number | null
          debut_mm?: number | null
          debut_yy?: number | null
          deleted_at?: string | null
          gender?: string | null
          group_id?: number | null
          id?: number
          image?: string | null
          is_kpop?: boolean
          is_musical?: boolean
          is_solo?: boolean
          mm?: number | null
          name?: Json | null
          updated_at?: string
          yy?: number | null
        }
        Update: {
          birth_date?: string | null
          created_at?: string
          dd?: number | null
          debut_date?: string | null
          debut_dd?: number | null
          debut_mm?: number | null
          debut_yy?: number | null
          deleted_at?: string | null
          gender?: string | null
          group_id?: number | null
          id?: number
          image?: string | null
          is_kpop?: boolean
          is_musical?: boolean
          is_solo?: boolean
          mm?: number | null
          name?: Json | null
          updated_at?: string
          yy?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "artist_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "artist_group"
            referencedColumns: ["id"]
          },
        ]
      }
      artist_group: {
        Row: {
          created_at: string
          debut_date: string | null
          debut_dd: number | null
          debut_mm: number | null
          debut_yy: number | null
          deleted_at: string | null
          id: number
          image: string | null
          name: Json | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          debut_date?: string | null
          debut_dd?: number | null
          debut_mm?: number | null
          debut_yy?: number | null
          deleted_at?: string | null
          id?: number
          image?: string | null
          name?: Json | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          debut_date?: string | null
          debut_dd?: number | null
          debut_mm?: number | null
          debut_yy?: number | null
          deleted_at?: string | null
          id?: number
          image?: string | null
          name?: Json | null
          updated_at?: string
        }
        Relationships: []
      }
      artist_user_bookmark: {
        Row: {
          artist_id: number | null
          created_at: string
          deleted_at: string | null
          id: number
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          artist_id?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          artist_id?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "artist_user_bookmark_artist_id_fk"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "artist_user_bookmark_user_profiles_id_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      artist_vote: {
        Row: {
          category: string | null
          content: Json | null
          created_at: string | null
          deleted_at: string | null
          id: number
          start_at: string | null
          stop_at: string | null
          title: Json | null
          updated_at: string | null
          visible_at: string | null
        }
        Insert: {
          category?: string | null
          content?: Json | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string | null
          visible_at?: string | null
        }
        Update: {
          category?: string | null
          content?: Json | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string | null
          visible_at?: string | null
        }
        Relationships: []
      }
      artist_vote_item: {
        Row: {
          artist_vote_id: number | null
          created_at: string | null
          deleted_at: string | null
          description: Json | null
          id: number
          title: Json | null
          updated_at: string | null
          vote_total: number | null
        }
        Insert: {
          artist_vote_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          description?: Json | null
          id?: number
          title?: Json | null
          updated_at?: string | null
          vote_total?: number | null
        }
        Update: {
          artist_vote_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          description?: Json | null
          id?: number
          title?: Json | null
          updated_at?: string | null
          vote_total?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "artist_vote_item_artist_vote_id_fkey"
            columns: ["artist_vote_id"]
            isOneToOne: false
            referencedRelation: "artist_vote"
            referencedColumns: ["id"]
          },
        ]
      }
      awsdms_ddl_audit: {
        Row: {
          c_ddlqry: string | null
          c_key: number
          c_name: string | null
          c_oid: number | null
          c_schema: string | null
          c_tag: string | null
          c_time: string | null
          c_txn: string | null
          c_user: string | null
        }
        Insert: {
          c_ddlqry?: string | null
          c_key?: number
          c_name?: string | null
          c_oid?: number | null
          c_schema?: string | null
          c_tag?: string | null
          c_time?: string | null
          c_txn?: string | null
          c_user?: string | null
        }
        Update: {
          c_ddlqry?: string | null
          c_key?: number
          c_name?: string | null
          c_oid?: number | null
          c_schema?: string | null
          c_tag?: string | null
          c_time?: string | null
          c_txn?: string | null
          c_user?: string | null
        }
        Relationships: []
      }
      banner: {
        Row: {
          celeb_id: number | null
          created_at: string | null
          deleted_at: string | null
          duration: number | null
          end_at: string | null
          id: number
          image: Json | null
          link: string | null
          location: string | null
          order: number | null
          start_at: string | null
          thumbnail: string | null
          title: Json
          updated_at: string | null
        }
        Insert: {
          celeb_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          duration?: number | null
          end_at?: string | null
          id?: number
          image?: Json | null
          link?: string | null
          location?: string | null
          order?: number | null
          start_at?: string | null
          thumbnail?: string | null
          title?: Json
          updated_at?: string | null
        }
        Update: {
          celeb_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          duration?: number | null
          end_at?: string | null
          id?: number
          image?: Json | null
          link?: string | null
          location?: string | null
          order?: number | null
          start_at?: string | null
          thumbnail?: string | null
          title?: Json
          updated_at?: string | null
        }
        Relationships: []
      }
      batch_log: {
        Row: {
          batch_name: string | null
          details: Json | null
          end_time: string | null
          id: number
          start_time: string | null
          status: string | null
        }
        Insert: {
          batch_name?: string | null
          details?: Json | null
          end_time?: string | null
          id?: number
          start_time?: string | null
          status?: string | null
        }
        Update: {
          batch_name?: string | null
          details?: Json | null
          end_time?: string | null
          id?: number
          start_time?: string | null
          status?: string | null
        }
        Relationships: []
      }
      blocked_ips: {
        Row: {
          blocked_at: string | null
          ip_address: string
          reason: string | null
        }
        Insert: {
          blocked_at?: string | null
          ip_address: string
          reason?: string | null
        }
        Update: {
          blocked_at?: string | null
          ip_address?: string
          reason?: string | null
        }
        Relationships: []
      }
      boards: {
        Row: {
          artist_id: number
          board_id: string
          created_at: string
          creator_id: string | null
          deleted_at: string | null
          description: string | null
          features: string[] | null
          id: string
          is_official: boolean | null
          name: Json
          order: number | null
          parent_board_id: string | null
          request_message: string | null
          status: Database["public"]["Enums"]["board_status_enum"]
          updated_at: string
        }
        Insert: {
          artist_id: number
          board_id?: string
          created_at?: string
          creator_id?: string | null
          deleted_at?: string | null
          description?: string | null
          features?: string[] | null
          id: string
          is_official?: boolean | null
          name: Json
          order?: number | null
          parent_board_id?: string | null
          request_message?: string | null
          status: Database["public"]["Enums"]["board_status_enum"]
          updated_at?: string
        }
        Update: {
          artist_id?: number
          board_id?: string
          created_at?: string
          creator_id?: string | null
          deleted_at?: string | null
          description?: string | null
          features?: string[] | null
          id?: string
          is_official?: boolean | null
          name?: Json
          order?: number | null
          parent_board_id?: string | null
          request_message?: string | null
          status?: Database["public"]["Enums"]["board_status_enum"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_boards_artist"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
        ]
      }
      bonus_expiry_log: {
        Row: {
          created_at: string | null
          details: Json | null
          id: number
          operation: string | null
        }
        Insert: {
          created_at?: string | null
          details?: Json | null
          id?: number
          operation?: string | null
        }
        Update: {
          created_at?: string | null
          details?: Json | null
          id?: number
          operation?: string | null
        }
        Relationships: []
      }
      celeb: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          id: number
          name_en: string | null
          name_ko: string | null
          thumbnail: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          name_en?: string | null
          name_ko?: string | null
          thumbnail?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          name_en?: string | null
          name_ko?: string | null
          thumbnail?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      celeb_bookmark_user: {
        Row: {
          celeb_id: number
          user_id: string | null
        }
        Insert: {
          celeb_id: number
          user_id?: string | null
        }
        Update: {
          celeb_id?: number
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "celeb_user_celeb_id_fkey"
            columns: ["celeb_id"]
            isOneToOne: false
            referencedRelation: "celeb"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_likes: {
        Row: {
          comment_id: string
          comment_like_id: string
          created_at: string
          deleted_at: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          comment_id: string
          comment_like_id?: string
          created_at?: string
          deleted_at?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          comment_id?: string
          comment_like_id?: string
          created_at?: string
          deleted_at?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_likes_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["comment_id"]
          },
        ]
      }
      comment_reports: {
        Row: {
          comment_id: string | null
          comment_report_id: string
          created_at: string | null
          deleted_at: string | null
          reason: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          comment_id?: string | null
          comment_report_id?: string
          created_at?: string | null
          deleted_at?: string | null
          reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          comment_id?: string | null
          comment_report_id?: string
          created_at?: string | null
          deleted_at?: string | null
          reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comment_reports_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["comment_id"]
          },
        ]
      }
      comments: {
        Row: {
          comment_id: string
          content: Json | null
          created_at: string
          deleted_at: string | null
          is_hidden: boolean | null
          likes: number
          locale: string | null
          parent_comment_id: string | null
          post_id: string
          replies: number
          updated_at: string
          user_id: string | null
        }
        Insert: {
          comment_id?: string
          content?: Json | null
          created_at?: string
          deleted_at?: string | null
          is_hidden?: boolean | null
          likes?: number
          locale?: string | null
          parent_comment_id?: string | null
          post_id: string
          replies?: number
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          comment_id?: string
          content?: Json | null
          created_at?: string
          deleted_at?: string | null
          is_hidden?: boolean | null
          likes?: number
          locale?: string | null
          parent_comment_id?: string | null
          post_id?: string
          replies?: number
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      compatibility_results: {
        Row: {
          artist_id: number
          completed_at: string | null
          created_at: string
          details: Json | null
          error_message: string | null
          gender: Database["public"]["Enums"]["user_gender_enum"] | null
          id: string
          idol_birth_date: string
          is_ads: boolean | null
          is_paid: boolean
          paid_at: string | null
          score: number | null
          status: Database["public"]["Enums"]["compatibility_status"]
          tips: Json | null
          user_birth_date: string
          user_birth_time: string | null
          user_id: string
        }
        Insert: {
          artist_id: number
          completed_at?: string | null
          created_at?: string
          details?: Json | null
          error_message?: string | null
          gender?: Database["public"]["Enums"]["user_gender_enum"] | null
          id?: string
          idol_birth_date: string
          is_ads?: boolean | null
          is_paid?: boolean
          paid_at?: string | null
          score?: number | null
          status?: Database["public"]["Enums"]["compatibility_status"]
          tips?: Json | null
          user_birth_date: string
          user_birth_time?: string | null
          user_id: string
        }
        Update: {
          artist_id?: number
          completed_at?: string | null
          created_at?: string
          details?: Json | null
          error_message?: string | null
          gender?: Database["public"]["Enums"]["user_gender_enum"] | null
          id?: string
          idol_birth_date?: string
          is_ads?: boolean | null
          is_paid?: boolean
          paid_at?: string | null
          score?: number | null
          status?: Database["public"]["Enums"]["compatibility_status"]
          tips?: Json | null
          user_birth_date?: string
          user_birth_time?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "compatibility_results_artist_id_fkey"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
        ]
      }
      compatibility_results_i18n: {
        Row: {
          compatibility_id: string
          compatibility_summary: string | null
          created_at: string
          details: Json | null
          id: string
          language: Database["public"]["Enums"]["supported_language"]
          score: number | null
          score_title: string | null
          tips: Json | null
          updated_at: string
        }
        Insert: {
          compatibility_id: string
          compatibility_summary?: string | null
          created_at?: string
          details?: Json | null
          id?: string
          language: Database["public"]["Enums"]["supported_language"]
          score?: number | null
          score_title?: string | null
          tips?: Json | null
          updated_at?: string
        }
        Update: {
          compatibility_id?: string
          compatibility_summary?: string | null
          created_at?: string
          details?: Json | null
          id?: string
          language?: Database["public"]["Enums"]["supported_language"]
          score?: number | null
          score_title?: string | null
          tips?: Json | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_compatibility"
            columns: ["compatibility_id"]
            isOneToOne: false
            referencedRelation: "compatibility_results"
            referencedColumns: ["id"]
          },
        ]
      }
      compatibility_score_descriptions: {
        Row: {
          score: number | null
          summary_en: string
          summary_ja: string
          summary_ko: string
          summary_zh: string
          title_en: string | null
          title_ja: string | null
          title_ko: string | null
          title_zh: string | null
        }
        Insert: {
          score?: number | null
          summary_en: string
          summary_ja: string
          summary_ko: string
          summary_zh: string
          title_en?: string | null
          title_ja?: string | null
          title_ko?: string | null
          title_zh?: string | null
        }
        Update: {
          score?: number | null
          summary_en?: string
          summary_ja?: string
          summary_ko?: string
          summary_zh?: string
          title_en?: string | null
          title_ja?: string | null
          title_ko?: string | null
          title_zh?: string | null
        }
        Relationships: []
      }
      config: {
        Row: {
          created_at: string | null
          id: string | null
          key: string
          updated_at: string
          value: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string | null
          key: string
          updated_at?: string
          value?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string | null
          key?: string
          updated_at?: string
          value?: string | null
        }
        Relationships: []
      }
      country_info: {
        Row: {
          country_code: string
          country_name: string
          gdp: number | null
          last_updated: string | null
          population: number | null
        }
        Insert: {
          country_code: string
          country_name: string
          gdp?: number | null
          last_updated?: string | null
          population?: number | null
        }
        Update: {
          country_code?: string
          country_name?: string
          gdp?: number | null
          last_updated?: string | null
          population?: number | null
        }
        Relationships: []
      }
      cron_logs: {
        Row: {
          created_at: string
          ended_at: string | null
          id: number
          job_name: string
          log_message: string | null
          started_at: string
          status: string | null
        }
        Insert: {
          created_at?: string
          ended_at?: string | null
          id?: number
          job_name: string
          log_message?: string | null
          started_at: string
          status?: string | null
        }
        Update: {
          created_at?: string
          ended_at?: string | null
          id?: number
          job_name?: string
          log_message?: string | null
          started_at?: string
          status?: string | null
        }
        Relationships: []
      }
      custom_logs: {
        Row: {
          details: Json | null
          log_id: number
          log_time: string | null
          operation: string | null
        }
        Insert: {
          details?: Json | null
          log_id?: number
          log_time?: string | null
          operation?: string | null
        }
        Update: {
          details?: Json | null
          log_id?: number
          log_time?: string | null
          operation?: string | null
        }
        Relationships: []
      }
      debug_db_logs: {
        Row: {
          detail: Json | null
          function_name: string
          id: number
          log_time: string | null
          step: string | null
        }
        Insert: {
          detail?: Json | null
          function_name: string
          id?: number
          log_time?: string | null
          step?: string | null
        }
        Update: {
          detail?: Json | null
          function_name?: string
          id?: number
          log_time?: string | null
          step?: string | null
        }
        Relationships: []
      }
      debug_logs: {
        Row: {
          created_at: string | null
          id: number
          log_message: string | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          log_message?: string | null
        }
        Update: {
          created_at?: string | null
          id?: number
          log_message?: string | null
        }
        Relationships: []
      }
      device_bans: {
        Row: {
          banned_at: string | null
          banned_by: string | null
          created_at: string | null
          device_id: string | null
          id: string
          reason: string | null
          unbanned_at: string | null
        }
        Insert: {
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string | null
          device_id?: string | null
          id?: string
          reason?: string | null
          unbanned_at?: string | null
        }
        Update: {
          banned_at?: string | null
          banned_by?: string | null
          created_at?: string | null
          device_id?: string | null
          id?: string
          reason?: string | null
          unbanned_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "device_bans_device_id_fkey"
            columns: ["device_id"]
            isOneToOne: false
            referencedRelation: "devices"
            referencedColumns: ["device_id"]
          },
        ]
      }
      devices: {
        Row: {
          app_build_number: string | null
          app_version: string | null
          ban_reason: string | null
          banned_at: string | null
          created_at: string | null
          device_id: string
          device_info: Json | null
          is_banned: boolean | null
          last_ip: string | null
          last_seen: string | null
          last_updated: string | null
          user_id: string | null
        }
        Insert: {
          app_build_number?: string | null
          app_version?: string | null
          ban_reason?: string | null
          banned_at?: string | null
          created_at?: string | null
          device_id: string
          device_info?: Json | null
          is_banned?: boolean | null
          last_ip?: string | null
          last_seen?: string | null
          last_updated?: string | null
          user_id?: string | null
        }
        Update: {
          app_build_number?: string | null
          app_version?: string | null
          ban_reason?: string | null
          banned_at?: string | null
          created_at?: string | null
          device_id?: string
          device_info?: Json | null
          is_banned?: boolean | null
          last_ip?: string | null
          last_seen?: string | null
          last_updated?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      faqs: {
        Row: {
          answer: Json
          category: string | null
          created_at: string | null
          created_by: string | null
          id: number
          order_number: number | null
          question: Json
          status: string | null
          updated_at: string | null
        }
        Insert: {
          answer: Json
          category?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          order_number?: number | null
          question: Json
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          answer?: Json
          category?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          order_number?: number | null
          question?: Json
          status?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "faqs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      fortune_batch_log: {
        Row: {
          completed_at: string | null
          created_at: string | null
          failed_count: number | null
          id: number
          processed_count: number | null
          status: string | null
          total_artists: number | null
          year: number | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          failed_count?: number | null
          id?: number
          processed_count?: number | null
          status?: string | null
          total_artists?: number | null
          year?: number | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          failed_count?: number | null
          id?: number
          processed_count?: number | null
          status?: string | null
          total_artists?: number | null
          year?: number | null
        }
        Relationships: []
      }
      fortune_generation_log: {
        Row: {
          artist_id: number | null
          created_at: string | null
          error_message: string | null
          id: number
          status: string | null
          year: number | null
        }
        Insert: {
          artist_id?: number | null
          created_at?: string | null
          error_message?: string | null
          id?: number
          status?: string | null
          year?: number | null
        }
        Update: {
          artist_id?: number | null
          created_at?: string | null
          error_message?: string | null
          id?: number
          status?: string | null
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "fortune_generation_log_artist_id_fkey"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
        ]
      }
      fortune_telling: {
        Row: {
          advice: string[]
          artist_id: number
          aspects: Json
          created_at: string | null
          id: string
          lucky: Json
          monthly_fortunes: Json
          overall_luck: string
          updated_at: string | null
          year: number
        }
        Insert: {
          advice: string[]
          artist_id: number
          aspects: Json
          created_at?: string | null
          id?: string
          lucky: Json
          monthly_fortunes: Json
          overall_luck: string
          updated_at?: string | null
          year: number
        }
        Update: {
          advice?: string[]
          artist_id?: number
          aspects?: Json
          created_at?: string | null
          id?: string
          lucky?: Json
          monthly_fortunes?: Json
          overall_luck?: string
          updated_at?: string | null
          year?: number
        }
        Relationships: [
          {
            foreignKeyName: "fortune_telling_artist_id_fkey"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
        ]
      }
      fortune_telling_i18n: {
        Row: {
          advice: string[]
          artist_id: number
          aspects: Json
          created_at: string | null
          fortune_id: string
          id: string
          language: string
          lucky: Json
          monthly_fortunes: Json
          overall_luck: string
          updated_at: string | null
          year: number
        }
        Insert: {
          advice: string[]
          artist_id: number
          aspects: Json
          created_at?: string | null
          fortune_id: string
          id?: string
          language: string
          lucky: Json
          monthly_fortunes: Json
          overall_luck: string
          updated_at?: string | null
          year: number
        }
        Update: {
          advice?: string[]
          artist_id?: number
          aspects?: Json
          created_at?: string | null
          fortune_id?: string
          id?: string
          language?: string
          lucky?: Json
          monthly_fortunes?: Json
          overall_luck?: string
          updated_at?: string | null
          year?: number
        }
        Relationships: [
          {
            foreignKeyName: "fortune_telling_i18n_artist_id_fkey"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fortune_telling_i18n_fortune_id_artist_id_year_fkey"
            columns: ["fortune_id", "artist_id", "year"]
            isOneToOne: false
            referencedRelation: "fortune_telling"
            referencedColumns: ["id", "artist_id", "year"]
          },
          {
            foreignKeyName: "fortune_telling_i18n_fortune_id_fkey"
            columns: ["fortune_id"]
            isOneToOne: false
            referencedRelation: "fortune_telling"
            referencedColumns: ["id"]
          },
        ]
      }
      gallery: {
        Row: {
          celeb_id: number
          cover: string | null
          created_at: string
          deleted_at: string | null
          id: number
          title: Json | null
          title_en: string | null
          title_ko: string | null
          updated_at: string
        }
        Insert: {
          celeb_id: number
          cover?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          title?: Json | null
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string
        }
        Update: {
          celeb_id?: number
          cover?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          title?: Json | null
          title_en?: string | null
          title_ko?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "gallery_celeb_id_fkey"
            columns: ["celeb_id"]
            isOneToOne: false
            referencedRelation: "celeb"
            referencedColumns: ["id"]
          },
        ]
      }
      gallery_user: {
        Row: {
          gallery_id: number | null
          user_id: number | null
        }
        Insert: {
          gallery_id?: number | null
          user_id?: number | null
        }
        Update: {
          gallery_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      ip_country_mapping: {
        Row: {
          country_code: string
          id: number
          ip_range_end: number
          ip_range_start: number
          last_updated: string | null
        }
        Insert: {
          country_code: string
          id?: number
          ip_range_end: number
          ip_range_start: number
          last_updated?: string | null
        }
        Update: {
          country_code?: string
          id?: number
          ip_range_end?: number
          ip_range_start?: number
          last_updated?: string | null
        }
        Relationships: []
      }
      library: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          id: number | null
          title: string | null
          updated_at: string | null
          user_id: number | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          title?: string | null
          updated_at?: string | null
          user_id?: number | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          title?: string | null
          updated_at?: string | null
          user_id?: number | null
        }
        Relationships: []
      }
      library_image: {
        Row: {
          image_id: number | null
          library_id: number | null
        }
        Insert: {
          image_id?: number | null
          library_id?: number | null
        }
        Update: {
          image_id?: number | null
          library_id?: number | null
        }
        Relationships: []
      }
      media: {
        Row: {
          created_at: string
          deleted_at: string | null
          id: number
          thumbnail_url: string | null
          title: Json | null
          updated_at: string
          video_id: string | null
          video_url: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          id?: number
          thumbnail_url?: string | null
          title?: Json | null
          updated_at?: string
          video_id?: string | null
          video_url?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          id?: number
          thumbnail_url?: string | null
          title?: Json | null
          updated_at?: string
          video_id?: string | null
          video_url?: string | null
        }
        Relationships: []
      }
      notices: {
        Row: {
          content: Json
          created_at: string | null
          created_by: string | null
          id: number
          is_pinned: boolean | null
          status: string | null
          title: Json
          updated_at: string | null
        }
        Insert: {
          content: Json
          created_at?: string | null
          created_by?: string | null
          id?: number
          is_pinned?: boolean | null
          status?: string | null
          title: Json
          updated_at?: string | null
        }
        Update: {
          content?: Json
          created_at?: string | null
          created_by?: string | null
          id?: number
          is_pinned?: boolean | null
          status?: string | null
          title?: Json
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notices_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      partition_creation_log: {
        Row: {
          created_at: string | null
          id: number
          message: string | null
        }
        Insert: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Update: {
          created_at?: string | null
          id?: number
          message?: string | null
        }
        Relationships: []
      }
      permissions: {
        Row: {
          action: string
          created_at: string | null
          description: string | null
          id: string
          resource: string
          updated_at: string | null
        }
        Insert: {
          action: string
          created_at?: string | null
          description?: string | null
          id?: string
          resource: string
          updated_at?: string | null
        }
        Update: {
          action?: string
          created_at?: string | null
          description?: string | null
          id?: string
          resource?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      pic_vote: {
        Row: {
          area: string | null
          created_at: string
          deleted_at: string | null
          id: number
          main_image: string | null
          order: number | null
          result_image: string | null
          start_at: string | null
          stop_at: string | null
          title: Json | null
          updated_at: string
          visible_at: string | null
          vote_category: string | null
          vote_content: string | null
          wait_image: string | null
        }
        Insert: {
          area?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          main_image?: string | null
          order?: number | null
          result_image?: string | null
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string
          visible_at?: string | null
          vote_category?: string | null
          vote_content?: string | null
          wait_image?: string | null
        }
        Update: {
          area?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          main_image?: string | null
          order?: number | null
          result_image?: string | null
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string
          visible_at?: string | null
          vote_category?: string | null
          vote_content?: string | null
          wait_image?: string | null
        }
        Relationships: []
      }
      pic_vote_item: {
        Row: {
          artist_id: number | null
          created_at: string | null
          deleted_at: string | null
          group_id: number | null
          id: number
          updated_at: string | null
          vote_id: number | null
          vote_total: number | null
        }
        Insert: {
          artist_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          group_id?: number | null
          id?: number
          updated_at?: string | null
          vote_id?: number | null
          vote_total?: number | null
        }
        Update: {
          artist_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          group_id?: number | null
          id?: number
          updated_at?: string | null
          vote_id?: number | null
          vote_total?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "pic_vote_item_artist_group_id_fk"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "artist_group"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pic_vote_item_artist_id_fk"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pic_vote_item_pic_vote_id_fk"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "pic_vote"
            referencedColumns: ["id"]
          },
        ]
      }
      pic_vote_pick: {
        Row: {
          amount: number | null
          created_at: string | null
          deleted_at: string | null
          id: number
          updated_at: string | null
          user_id: string | null
          vote_id: number | null
          vote_item_id: number
        }
        Insert: {
          amount?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
          vote_id?: number | null
          vote_item_id: number
        }
        Update: {
          amount?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
          vote_id?: number | null
          vote_item_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "pic_vote_pick_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pic_vote_pick_vote_id_fkey"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "pic_vote"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pic_vote_pick_vote_item_id_fkey"
            columns: ["vote_item_id"]
            isOneToOne: false
            referencedRelation: "pic_vote_item"
            referencedColumns: ["id"]
          },
        ]
      }
      pic_vote_reward: {
        Row: {
          reward_id: number
          vote_id: number
        }
        Insert: {
          reward_id: number
          vote_id: number
        }
        Update: {
          reward_id?: number
          vote_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "pic_vote_reward_pic_vote_id_fk"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "pic_vote"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pic_vote_reward_reward_id_fk"
            columns: ["reward_id"]
            isOneToOne: false
            referencedRelation: "reward"
            referencedColumns: ["id"]
          },
        ]
      }
      policy: {
        Row: {
          content: string
          created_at: string
          deleted_at: string | null
          id: number
          language: Database["public"]["Enums"]["policy_language_enum"] | null
          type: string | null
          updated_at: string
          version: string
        }
        Insert: {
          content?: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          language?: Database["public"]["Enums"]["policy_language_enum"] | null
          type?: string | null
          updated_at?: string
          version?: string
        }
        Update: {
          content?: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          language?: Database["public"]["Enums"]["policy_language_enum"] | null
          type?: string | null
          updated_at?: string
          version?: string
        }
        Relationships: []
      }
      popup: {
        Row: {
          content: Json | null
          created_at: string | null
          deleted_at: string | null
          end_at: string | null
          id: number
          image: Json | null
          stat_at: string | null
          title: Json | null
          updated_at: string | null
        }
        Insert: {
          content?: Json | null
          created_at?: string | null
          deleted_at?: string | null
          end_at?: string | null
          id?: number
          image?: Json | null
          stat_at?: string | null
          title?: Json | null
          updated_at?: string | null
        }
        Update: {
          content?: Json | null
          created_at?: string | null
          deleted_at?: string | null
          end_at?: string | null
          id?: number
          image?: Json | null
          stat_at?: string | null
          title?: Json | null
          updated_at?: string | null
        }
        Relationships: []
      }
      post_attachments: {
        Row: {
          attachment_id: string
          file_name: string
          file_path: string
          file_size: number
          file_type: string
          post_id: string | null
        }
        Insert: {
          attachment_id?: string
          file_name: string
          file_path: string
          file_size: number
          file_type: string
          post_id?: string | null
        }
        Update: {
          attachment_id?: string
          file_name?: string
          file_path?: string
          file_size?: number
          file_type?: string
          post_id?: string | null
        }
        Relationships: []
      }
      post_reports: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          post_id: string | null
          post_report_id: string
          reason: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          post_id?: string | null
          post_report_id?: string
          reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          post_id?: string | null
          post_report_id?: string
          reason?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "post_reports_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["post_id"]
          },
        ]
      }
      post_scraps: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          post_id: string | null
          post_scrap_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          post_id?: string | null
          post_scrap_id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          post_id?: string | null
          post_scrap_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_scrap_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_scraps_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      post_views: {
        Row: {
          post_id: string
          user_id: string
          viewed_at: string | null
        }
        Insert: {
          post_id: string
          user_id: string
          viewed_at?: string | null
        }
        Update: {
          post_id?: string
          user_id?: string
          viewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "post_views_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["post_id"]
          },
          {
            foreignKeyName: "post_views_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          attachments: string[] | null
          board_id: string | null
          content: Json[] | null
          created_at: string
          deleted_at: string | null
          id: string
          is_anonymous: boolean
          is_hidden: boolean | null
          is_temporary: boolean
          post_id: string
          reply_count: number
          title: string
          updated_at: string | null
          user_id: string
          view_count: number
        }
        Insert: {
          attachments?: string[] | null
          board_id?: string | null
          content?: Json[] | null
          created_at?: string
          deleted_at?: string | null
          id: string
          is_anonymous?: boolean
          is_hidden?: boolean | null
          is_temporary?: boolean
          post_id?: string
          reply_count?: number
          title: string
          updated_at?: string | null
          user_id: string
          view_count?: number
        }
        Update: {
          attachments?: string[] | null
          board_id?: string | null
          content?: Json[] | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_anonymous?: boolean
          is_hidden?: boolean | null
          is_temporary?: boolean
          post_id?: string
          reply_count?: number
          title?: string
          updated_at?: string | null
          user_id?: string
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "posts_board_id_fkey"
            columns: ["board_id"]
            isOneToOne: false
            referencedRelation: "boards"
            referencedColumns: ["board_id"]
          },
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          created_at: string | null
          description: Json | null
          end_at: string | null
          id: string
          paypal_link: string | null
          platform: Database["public"]["Enums"]["platform_enum"]
          price: number | null
          product_name: string
          product_type: Database["public"]["Enums"]["product_type_enum"]
          star_candy: number | null
          star_candy_bonus: number | null
          start_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: Json | null
          end_at?: string | null
          id: string
          paypal_link?: string | null
          platform: Database["public"]["Enums"]["platform_enum"]
          price?: number | null
          product_name: string
          product_type: Database["public"]["Enums"]["product_type_enum"]
          star_candy?: number | null
          star_candy_bonus?: number | null
          start_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: Json | null
          end_at?: string | null
          id?: string
          paypal_link?: string | null
          platform?: Database["public"]["Enums"]["platform_enum"]
          price?: number | null
          product_name?: string
          product_type?: Database["public"]["Enums"]["product_type_enum"]
          star_candy?: number | null
          star_candy_bonus?: number | null
          start_at?: string | null
        }
        Relationships: []
      }
      prompt_usage_logs: {
        Row: {
          created_at: string | null
          error: string | null
          execution_time_ms: number | null
          id: string
          prompt_id: string | null
          response: Json
          token_count: number | null
          variables: Json
        }
        Insert: {
          created_at?: string | null
          error?: string | null
          execution_time_ms?: number | null
          id?: string
          prompt_id?: string | null
          response: Json
          token_count?: number | null
          variables: Json
        }
        Update: {
          created_at?: string | null
          error?: string | null
          execution_time_ms?: number | null
          id?: string
          prompt_id?: string | null
          response?: Json
          token_count?: number | null
          variables?: Json
        }
        Relationships: [
          {
            foreignKeyName: "prompt_usage_logs_prompt_id_fkey"
            columns: ["prompt_id"]
            isOneToOne: false
            referencedRelation: "prompts"
            referencedColumns: ["id"]
          },
        ]
      }
      prompts: {
        Row: {
          category: string
          created_at: string | null
          created_by: string
          description: string | null
          id: string
          is_active: boolean | null
          model_config: Json
          name: string
          tags: string[] | null
          template: string
          updated_at: string | null
          variables: string[]
          version: number
        }
        Insert: {
          category: string
          created_at?: string | null
          created_by: string
          description?: string | null
          id?: string
          is_active?: boolean | null
          model_config: Json
          name: string
          tags?: string[] | null
          template: string
          updated_at?: string | null
          variables: string[]
          version: number
        }
        Update: {
          category?: string
          created_at?: string | null
          created_by?: string
          description?: string | null
          id?: string
          is_active?: boolean | null
          model_config?: Json
          name?: string
          tags?: string[] | null
          template?: string
          updated_at?: string | null
          variables?: string[]
          version?: number
        }
        Relationships: []
      }
      qnas: {
        Row: {
          answer: string | null
          answered_at: string | null
          answered_by: string | null
          created_at: string | null
          created_by: string | null
          is_private: boolean | null
          qna_id: number
          question: string
          status: string | null
          title: string
          updated_at: string | null
        }
        Insert: {
          answer?: string | null
          answered_at?: string | null
          answered_by?: string | null
          created_at?: string | null
          created_by?: string | null
          is_private?: boolean | null
          qna_id?: number
          question: string
          status?: string | null
          title: string
          updated_at?: string | null
        }
        Update: {
          answer?: string | null
          answered_at?: string | null
          answered_by?: string | null
          created_at?: string | null
          created_by?: string | null
          is_private?: boolean | null
          qna_id?: number
          question?: string
          status?: string | null
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "qnas_answered_by_fkey"
            columns: ["answered_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "qnas_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      receipts: {
        Row: {
          created_at: string | null
          environment: string | null
          id: number
          platform: string
          product_id: string | null
          receipt_data: string
          receipt_hash: string | null
          status: string
          user_id: string | null
          verification_data: Json | null
        }
        Insert: {
          created_at?: string | null
          environment?: string | null
          id?: number
          platform: string
          product_id?: string | null
          receipt_data: string
          receipt_hash?: string | null
          status: string
          user_id?: string | null
          verification_data?: Json | null
        }
        Update: {
          created_at?: string | null
          environment?: string | null
          id?: number
          platform?: string
          product_id?: string | null
          receipt_data?: string
          receipt_hash?: string | null
          status?: string
          user_id?: string | null
          verification_data?: Json | null
        }
        Relationships: []
      }
      reward: {
        Row: {
          created_at: string
          deleted_at: string | null
          id: number
          location: Json | null
          location_images: string[] | null
          order: number | null
          overview_images: string[] | null
          size_guide: Json | null
          size_guide_images: string[] | null
          thumbnail: string | null
          title: Json | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          id?: number
          location?: Json | null
          location_images?: string[] | null
          order?: number | null
          overview_images?: string[] | null
          size_guide?: Json | null
          size_guide_images?: string[] | null
          thumbnail?: string | null
          title?: Json | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          id?: number
          location?: Json | null
          location_images?: string[] | null
          order?: number | null
          overview_images?: string[] | null
          size_guide?: Json | null
          size_guide_images?: string[] | null
          thumbnail?: string | null
          title?: Json | null
          updated_at?: string
        }
        Relationships: []
      }
      role_permissions: {
        Row: {
          created_at: string | null
          id: string
          permission_id: string
          role_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          permission_id: string
          role_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          permission_id?: string
          role_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      role_users: {
        Row: {
          created_at: string | null
          id: string
          role_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          role_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          role_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_users_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      star_candy_bonus_history: {
        Row: {
          amount: number | null
          created_at: string
          deleted_at: string | null
          expired_dt: string | null
          id: number
          parent_id: number | null
          remain_amount: number
          transaction_id: string | null
          type: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at: string
          user_id: string
          vote_pick_id: number | null
        }
        Insert: {
          amount?: number | null
          created_at?: string
          deleted_at?: string | null
          expired_dt?: string | null
          id?: number
          parent_id?: number | null
          remain_amount?: number
          transaction_id?: string | null
          type?: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at?: string
          user_id: string
          vote_pick_id?: number | null
        }
        Update: {
          amount?: number | null
          created_at?: string
          deleted_at?: string | null
          expired_dt?: string | null
          id?: number
          parent_id?: number | null
          remain_amount?: number
          transaction_id?: string | null
          type?: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at?: string
          user_id?: string
          vote_pick_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "star_candy_bonus_history_user_profiles_id_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      star_candy_history: {
        Row: {
          amount: number | null
          created_at: string
          deleted_at: string | null
          id: number
          parent_id: number | null
          transaction_id: string | null
          type: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at: string
          user_id: string
          vote_pick_id: number | null
        }
        Insert: {
          amount?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          parent_id?: number | null
          transaction_id?: string | null
          type?: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at?: string
          user_id: string
          vote_pick_id?: number | null
        }
        Update: {
          amount?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          parent_id?: number | null
          transaction_id?: string | null
          type?: Database["public"]["Enums"]["candy_history_type"] | null
          updated_at?: string
          user_id?: string
          vote_pick_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "star_candy_history_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "vote_pick"
            referencedColumns: ["id"]
          },
        ]
      }
      transaction_admob: {
        Row: {
          ad_network: string | null
          created_at: string
          deleted_at: string | null
          key_id: string | null
          reward_amount: number | null
          reward_type: string | null
          signature: string | null
          transaction_id: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          key_id?: string | null
          reward_amount?: number | null
          reward_type?: string | null
          signature?: string | null
          transaction_id: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          key_id?: string | null
          reward_amount?: number | null
          reward_type?: string | null
          signature?: string | null
          transaction_id?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      transaction_pangle: {
        Row: {
          ad_network: string | null
          created_at: string
          deleted_at: string | null
          key_id: string | null
          platform: string | null
          reward_amount: number | null
          reward_name: string | null
          reward_type: string | null
          signature: string | null
          transaction_id: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          key_id?: string | null
          platform?: string | null
          reward_amount?: number | null
          reward_name?: string | null
          reward_type?: string | null
          signature?: string | null
          transaction_id: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          key_id?: string | null
          platform?: string | null
          reward_amount?: number | null
          reward_name?: string | null
          reward_type?: string | null
          signature?: string | null
          transaction_id?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      transaction_pincrux: {
        Row: {
          ad_network: string | null
          app_key: string | null
          app_title: string | null
          commission: number | null
          created_at: string
          deleted_at: string | null
          menu_category1: string | null
          pub_key: number | null
          reward_amount: number | null
          reward_type: string | null
          signature: string | null
          transaction_id: string
          updated_at: string
          usr_key: string | null
        }
        Insert: {
          ad_network?: string | null
          app_key?: string | null
          app_title?: string | null
          commission?: number | null
          created_at?: string
          deleted_at?: string | null
          menu_category1?: string | null
          pub_key?: number | null
          reward_amount?: number | null
          reward_type?: string | null
          signature?: string | null
          transaction_id: string
          updated_at?: string
          usr_key?: string | null
        }
        Update: {
          ad_network?: string | null
          app_key?: string | null
          app_title?: string | null
          commission?: number | null
          created_at?: string
          deleted_at?: string | null
          menu_category1?: string | null
          pub_key?: number | null
          reward_amount?: number | null
          reward_type?: string | null
          signature?: string | null
          transaction_id?: string
          updated_at?: string
          usr_key?: string | null
        }
        Relationships: []
      }
      transaction_tapjoy: {
        Row: {
          created_at: string
          id: number
          platform: string | null
          reward_amount: number
          reward_type: string | null
          transaction_id: string
          user_id: string
          verifier: string | null
        }
        Insert: {
          created_at?: string
          id?: number
          platform?: string | null
          reward_amount: number
          reward_type?: string | null
          transaction_id: string
          user_id: string
          verifier?: string | null
        }
        Update: {
          created_at?: string
          id?: number
          platform?: string | null
          reward_amount?: number
          reward_type?: string | null
          transaction_id?: string
          user_id?: string
          verifier?: string | null
        }
        Relationships: []
      }
      transaction_unity: {
        Row: {
          ad_network: string | null
          created_at: string
          deleted_at: string | null
          hmac: string
          reward_amount: number | null
          reward_type: string | null
          transaction_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          hmac: string
          reward_amount?: number | null
          reward_type?: string | null
          transaction_id: string
          updated_at?: string
          user_id: string
        }
        Update: {
          ad_network?: string | null
          created_at?: string
          deleted_at?: string | null
          hmac?: string
          reward_amount?: number | null
          reward_type?: string | null
          transaction_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_agreement: {
        Row: {
          created_at: string | null
          deleted_at: string | null
          id: string
          privacy: string | null
          terms: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          deleted_at?: string | null
          id: string
          privacy?: string | null
          terms?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          deleted_at?: string | null
          id?: string
          privacy?: string | null
          terms?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_agreement_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_blocks: {
        Row: {
          blocked_user_id: string
          created_at: string
          deleted_at: string | null
          id: string
          user_id: string
        }
        Insert: {
          blocked_user_id: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          user_id: string
        }
        Update: {
          blocked_user_id?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          user_id?: string
        }
        Relationships: []
      }
      user_comment_like: {
        Row: {
          comment_id: number | null
          created_at: string | null
          deleted_at: string | null
          id: number | null
          updated_at: string | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Relationships: []
      }
      user_comment_report: {
        Row: {
          comment_id: number | null
          created_at: string | null
          deleted_at: string | null
          id: number | null
          updated_at: string | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          updated_at?: string | null
          user_id?: number | null
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          birth_date: string | null
          birth_time: string | null
          created_at: string
          deleted_at: string | null
          email: string | null
          gender: Database["public"]["Enums"]["user_gender_enum"] | null
          id: string
          is_admin: boolean
          nickname: string | null
          open_ages: boolean
          open_gender: boolean
          star_candy: number
          star_candy_bonus: number
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          birth_date?: string | null
          birth_time?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          gender?: Database["public"]["Enums"]["user_gender_enum"] | null
          id: string
          is_admin?: boolean
          nickname?: string | null
          open_ages?: boolean
          open_gender?: boolean
          star_candy?: number
          star_candy_bonus?: number
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          birth_date?: string | null
          birth_time?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          gender?: Database["public"]["Enums"]["user_gender_enum"] | null
          id?: string
          is_admin?: boolean
          nickname?: string | null
          open_ages?: boolean
          open_gender?: boolean
          star_candy?: number
          star_candy_bonus?: number
          updated_at?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          created_at: string | null
          id: string
          role_id: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          role_id: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          role_id?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      version: {
        Row: {
          android: Json | null
          created_at: string
          deleted_at: string | null
          id: number
          ios: Json | null
          linux: Json | null
          macos: Json | null
          updated_at: string
          windows: Json | null
        }
        Insert: {
          android?: Json | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          ios?: Json | null
          linux?: Json | null
          macos?: Json | null
          updated_at?: string
          windows?: Json | null
        }
        Update: {
          android?: Json | null
          created_at?: string
          deleted_at?: string | null
          id?: number
          ios?: Json | null
          linux?: Json | null
          macos?: Json | null
          updated_at?: string
          windows?: Json | null
        }
        Relationships: []
      }
      vote: {
        Row: {
          area: string
          created_at: string
          deleted_at: string | null
          id: number
          main_image: string | null
          order: number | null
          result_image: string | null
          start_at: string | null
          stop_at: string | null
          title: Json | null
          updated_at: string
          visible_at: string | null
          vote_category: string | null
          vote_content: string | null
          vote_sub_category: string | null
          wait_image: string | null
        }
        Insert: {
          area: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          main_image?: string | null
          order?: number | null
          result_image?: string | null
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string
          visible_at?: string | null
          vote_category?: string | null
          vote_content?: string | null
          vote_sub_category?: string | null
          wait_image?: string | null
        }
        Update: {
          area?: string
          created_at?: string
          deleted_at?: string | null
          id?: number
          main_image?: string | null
          order?: number | null
          result_image?: string | null
          start_at?: string | null
          stop_at?: string | null
          title?: Json | null
          updated_at?: string
          visible_at?: string | null
          vote_category?: string | null
          vote_content?: string | null
          vote_sub_category?: string | null
          wait_image?: string | null
        }
        Relationships: []
      }
      vote_achieve: {
        Row: {
          amount: number | null
          id: number | null
          order: number | null
          reward_id: number | null
          vote_id: number | null
        }
        Insert: {
          amount?: number | null
          id?: number | null
          order?: number | null
          reward_id?: number | null
          vote_id?: number | null
        }
        Update: {
          amount?: number | null
          id?: number | null
          order?: number | null
          reward_id?: number | null
          vote_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "vote_achieve_reward_id_fk"
            columns: ["reward_id"]
            isOneToOne: false
            referencedRelation: "reward"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_achieve_vote_id_fk"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "vote"
            referencedColumns: ["id"]
          },
        ]
      }
      vote_comment: {
        Row: {
          childrencount: number | null
          content: string | null
          created_at: string | null
          deleted_at: string | null
          id: number | null
          likes: number | null
          parent_id: number | null
          updated_at: string | null
          user_id: number | null
          vote_id: number | null
        }
        Insert: {
          childrencount?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          likes?: number | null
          parent_id?: number | null
          updated_at?: string | null
          user_id?: number | null
          vote_id?: number | null
        }
        Update: {
          childrencount?: number | null
          content?: string | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number | null
          likes?: number | null
          parent_id?: number | null
          updated_at?: string | null
          user_id?: number | null
          vote_id?: number | null
        }
        Relationships: []
      }
      vote_comment_like: {
        Row: {
          comment_id: number | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      vote_comment_report: {
        Row: {
          comment_id: number | null
          user_id: number | null
        }
        Insert: {
          comment_id?: number | null
          user_id?: number | null
        }
        Update: {
          comment_id?: number | null
          user_id?: number | null
        }
        Relationships: []
      }
      vote_item: {
        Row: {
          artist_id: number | null
          created_at: string | null
          deleted_at: string | null
          group_id: number
          id: number
          updated_at: string | null
          vote_id: number | null
          vote_total: number | null
        }
        Insert: {
          artist_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          group_id?: number
          id?: number
          updated_at?: string | null
          vote_id?: number | null
          vote_total?: number | null
        }
        Update: {
          artist_id?: number | null
          created_at?: string | null
          deleted_at?: string | null
          group_id?: number
          id?: number
          updated_at?: string | null
          vote_id?: number | null
          vote_total?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "vote_item_artist_id_fk"
            columns: ["artist_id"]
            isOneToOne: false
            referencedRelation: "artist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_item_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "artist_group"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_item_vote_id_fk"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "vote"
            referencedColumns: ["id"]
          },
        ]
      }
      vote_pick: {
        Row: {
          amount: number | null
          created_at: string | null
          deleted_at: string | null
          id: number
          updated_at: string | null
          user_id: string | null
          vote_id: number | null
          vote_item_id: number
        }
        Insert: {
          amount?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
          vote_id?: number | null
          vote_item_id: number
        }
        Update: {
          amount?: number | null
          created_at?: string | null
          deleted_at?: string | null
          id?: number
          updated_at?: string | null
          user_id?: string | null
          vote_id?: number | null
          vote_item_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "vote_pick_user_profiles_id_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_pick_vote_id_fkey"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "vote"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_pick_vote_item_id_fkey"
            columns: ["vote_item_id"]
            isOneToOne: false
            referencedRelation: "vote_item"
            referencedColumns: ["id"]
          },
        ]
      }
      vote_reward: {
        Row: {
          reward_id: number
          vote_id: number
        }
        Insert: {
          reward_id: number
          vote_id: number
        }
        Update: {
          reward_id?: number
          vote_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "vote_reward_reward_id_fkey"
            columns: ["reward_id"]
            isOneToOne: false
            referencedRelation: "reward"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_reward_vote_id_fkey"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "vote"
            referencedColumns: ["id"]
          },
        ]
      }
      vote_share_bonus: {
        Row: {
          amount: number
          created_at: string
          id: number
          updated_at: string
          user_id: string
          vote_id: number
        }
        Insert: {
          amount: number
          created_at?: string
          id?: number
          updated_at?: string
          user_id: string
          vote_id: number
        }
        Update: {
          amount?: number
          created_at?: string
          id?: number
          updated_at?: string
          user_id?: string
          vote_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "vote_share_bonus_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "vote_share_bonus_vote_id_fkey"
            columns: ["vote_id"]
            isOneToOne: false
            referencedRelation: "vote"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      view_transaction_all: {
        Row: {
          ad_network: string | null
          commission: number | null
          created_at: string | null
          platform: string | null
          reward_amount: number | null
          reward_name: string | null
          reward_type: string | null
          source: string | null
          transaction_id: string | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      begin_transaction: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      bytea_to_text: {
        Args: { data: string }
        Returns: string
      }
      can_vote: {
        Args: { p_user_id: string; p_vote_amount: number }
        Returns: boolean
      }
      check_bonus_state: {
        Args: { check_time?: string }
        Returns: {
          total_bonuses: number
          active_bonuses: number
          expirable_bonuses: number
          earliest_expiry: string
          latest_expiry: string
        }[]
      }
      commit_transaction: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      create_boards_for_existing_artists: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      create_boards_for_existing_artists_meme: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      create_monthly_votes: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      deduct_star_candy: {
        Args: { p_user_id: string; p_amount: number; p_vote_pick_id: number }
        Returns: undefined
      }
      deduct_star_candy_bonus: {
        Args: {
          p_user_id: string
          p_amount: number
          p_bonus_id: number
          p_vote_pick_id: number
        }
        Returns: undefined
      }
      expire_star_candy_bonus: {
        Args: { expiry_time?: string }
        Returns: {
          expired_count: number
          expired_amount: number
          affected_users: number
        }[]
      }
      get_current_splash_image: {
        Args: Record<PropertyKey, never>
        Returns: {
          celeb_id: number | null
          created_at: string | null
          deleted_at: string | null
          duration: number | null
          end_at: string | null
          id: number
          image: Json | null
          link: string | null
          location: string | null
          order: number | null
          start_at: string | null
          thumbnail: string | null
          title: Json
          updated_at: string | null
        }[]
      }
      get_expiring_bonus_prediction: {
        Args: Record<PropertyKey, never>
        Returns: {
          prediction_month: string
          expiring_amount: number
        }[]
      }
      get_vote_and_user_info: {
        Args: { p_vote_id: number; p_user_id: number }
        Returns: {
          stop_at: string
          star_candy: number
          star_candy_bonus: number
          total_bonus_remain: number
        }[]
      }
      http: {
        Args: { request: Database["public"]["CompositeTypes"]["http_request"] }
        Returns: unknown
      }
      http_delete: {
        Args:
          | { uri: string }
          | { uri: string; content: string; content_type: string }
        Returns: unknown
      }
      http_get: {
        Args: { uri: string } | { uri: string; data: Json }
        Returns: unknown
      }
      http_head: {
        Args: { uri: string }
        Returns: unknown
      }
      http_header: {
        Args: { field: string; value: string }
        Returns: Database["public"]["CompositeTypes"]["http_header"]
      }
      http_list_curlopt: {
        Args: Record<PropertyKey, never>
        Returns: {
          curlopt: string
          value: string
        }[]
      }
      http_patch: {
        Args: { uri: string; content: string; content_type: string }
        Returns: unknown
      }
      http_post: {
        Args:
          | { uri: string; content: string; content_type: string }
          | { uri: string; data: Json }
        Returns: unknown
      }
      http_put: {
        Args: { uri: string; content: string; content_type: string }
        Returns: unknown
      }
      http_reset_curlopt: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      http_set_curlopt: {
        Args: { curlopt: string; value: string }
        Returns: boolean
      }
      increment_user_star_candy_bonus: {
        Args: { p_user_id: string; p_amount: number }
        Returns: undefined
      }
      increment_view_count: {
        Args: { post_id_param: string; viewer_id?: string }
        Returns: undefined
      }
      perform_pic_vote_transaction: {
        Args: {
          p_vote_id: number
          p_vote_item_id: number
          p_amount: number
          p_user_id: string
        }
        Returns: Json
      }
      perform_vote_deduction: {
        Args: {
          p_user_id: string
          p_vote_amount: number
          p_vote_pick_id: number
        }
        Returns: undefined
      }
      perform_vote_transaction: {
        Args: {
          p_vote_id: number
          p_vote_item_id: number
          p_amount: number
          p_user_id: string
        }
        Returns: Json
      }
      process_compatibility_payment: {
        Args: {
          p_user_id: string
          p_compatibility_id: string
          p_star_candy_amount: number
        }
        Returns: undefined
      }
      process_vote: {
        Args: {
          p_vote_id: number
          p_vote_item_id: number
          p_amount: number
          p_user_id: string
          p_total_bonus_remain: number
        }
        Returns: {
          vote_total: number
        }[]
      }
      rollback_transaction: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      test_expire_star_candy_bonus: {
        Args: { test_datetime: string }
        Returns: {
          operation: string
          details: Json
        }[]
      }
      text_to_bytea: {
        Args: { data: string }
        Returns: string
      }
      urlencode: {
        Args: { data: Json } | { string: string } | { string: string }
        Returns: string
      }
    }
    Enums: {
      board_status_enum: "pending" | "approved" | "rejected"
      candy_history_type:
        | "AD"
        | "VOTE"
        | "PURCHASE"
        | "GIFT"
        | "EXPIRED"
        | "VOTE_SHARE_BONUS"
        | "OPEN_COMPATIBILITY"
        | "MISSION"
      compatibility_status: "pending" | "completed" | "error"
      platform_enum: "iOS" | "Android" | "Both"
      policy_language_enum: "ko" | "en"
      policy_type_enum:
        | "PRIVACY_KO"
        | "PRIVACY_EN"
        | "TERMS_KO"
        | "TERMS_EN"
        | "WITHDRAW_ACCOUNT_KO"
        | "WITHDRAW_ACCOUNT_EN"
      portal_enum: "vote" | "pic"
      product_type_enum: "consumable" | "non-consumable" | "subscription"
      specific_platform_enum: "iOS" | "Android"
      supported_language: "ko" | "en" | "ja" | "zh"
      user_gender_enum: "male" | "female" | "other"
    }
    CompositeTypes: {
      http_header: {
        field: string | null
        value: string | null
      }
      http_request: {
        method: unknown | null
        uri: string | null
        headers: Database["public"]["CompositeTypes"]["http_header"][] | null
        content_type: string | null
        content: string | null
      }
      http_response: {
        status: number | null
        content_type: string | null
        headers: Database["public"]["CompositeTypes"]["http_header"][] | null
        content: string | null
      }
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      board_status_enum: ["pending", "approved", "rejected"],
      candy_history_type: [
        "AD",
        "VOTE",
        "PURCHASE",
        "GIFT",
        "EXPIRED",
        "VOTE_SHARE_BONUS",
        "OPEN_COMPATIBILITY",
        "MISSION",
      ],
      compatibility_status: ["pending", "completed", "error"],
      platform_enum: ["iOS", "Android", "Both"],
      policy_language_enum: ["ko", "en"],
      policy_type_enum: [
        "PRIVACY_KO",
        "PRIVACY_EN",
        "TERMS_KO",
        "TERMS_EN",
        "WITHDRAW_ACCOUNT_KO",
        "WITHDRAW_ACCOUNT_EN",
      ],
      portal_enum: ["vote", "pic"],
      product_type_enum: ["consumable", "non-consumable", "subscription"],
      specific_platform_enum: ["iOS", "Android"],
      supported_language: ["ko", "en", "ja", "zh"],
      user_gender_enum: ["male", "female", "other"],
    },
  },
} as const
