export interface Media {
  id: number;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  video_url: string | null;
  title: Record<string, string>; // JSON 타입이므로 Record 형태로 정의
  thumbnail_url: string | null;
  video_id: string | null;
}
