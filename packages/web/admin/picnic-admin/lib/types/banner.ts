export interface Banner {
  id: number;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
  thumbnail: string | null;
  start_at: Date | null;
  end_at: Date | null;
  celeb_id: number | null;
  location: string | null;
  title: Record<string, string>;
  image: Record<string, any> | null;
  order: number | null;
  duration: number | null;
  link: string | null;
}