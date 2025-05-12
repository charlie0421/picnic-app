import { MultilingualText } from './common';

export type { MultilingualText };

export interface Popup {
  id: string;
  title: MultilingualText;
  content: string;
  image: MultilingualText;
  start_at: string;
  stop_at: string;
  created_at: string;
  updated_at: string;
}

export interface PopupFormData {
  title_ko: string;
  title_en: string;
  title_ja: string;
  title_zh: string;
  title_id: string;
  content_ko: string;
  content_en: string;
  content_ja: string;
  content_zh: string;
  content_id: string;
  image: MultilingualText;
  start_at: string;
  stop_at: string;
}
