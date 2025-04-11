export interface Reward {
  id: number;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
  thumbnail?: string;
  overview_images?: string[];
  location_images?: string[];
  size_guide_images?: string[];
  title?: {
    [key: string]: string;
  };
  location?: {
    [key: string]: string | any;
  };
  size_guide?: {
    [key: string]: any;
  };
  order?: number;
}

export interface SizeGuideItem {
  desc: string[] | string;
  image?: string[];
}

export const defaultLocalizations = ['ko', 'en', 'ja', 'zh']; 