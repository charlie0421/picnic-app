import { MultilingualText } from './common';
import { supportedLocales } from '@/lib/utils/translation';

export type { MultilingualText };

export type PlatformEnum = 'all' | 'android' | 'ios' | 'web';

export interface Popup {
  id: string;
  title: MultilingualText;
  content: MultilingualText;
  image: MultilingualText;
  start_at: string;
  stop_at: string;
  platform: PlatformEnum;
  created_at: string;
  updated_at: string;
}

type MultilingualFormFields<T extends readonly string[]> = {
  [K in T[number] as `title_${K}`]: string;
} & {
  [K in T[number] as `content_${K}`]: string;
};

export type PopupFormData = MultilingualFormFields<typeof supportedLocales> & {
  image: MultilingualText;
  start_at: string;
  stop_at: string;
  platform: PlatformEnum;
};

// PopupFormData를 Popup 객체로 변환 (자동화)
export function convertFormDataToPopup(
  formData: any,
): Omit<Popup, 'id' | 'created_at'> {
  const title: MultilingualText = {} as MultilingualText;
  const content: MultilingualText = {} as MultilingualText;
  supportedLocales.forEach((locale) => {
    title[locale] = formData[`title_${locale}`] || '';
    content[locale] = formData[`content_${locale}`] || '';
  });
  return {
    title,
    content,
    image: formData.image,
    start_at: formData.start_at,
    stop_at: formData.stop_at,
    platform: formData.platform,
    updated_at: new Date().toISOString(),
  };
}

// Popup 객체를 PopupFormData로 변환 (자동화)
export function convertPopupToFormData(popup?: Popup): any {
  const result: any = {};
  if (popup?.title) {
    supportedLocales.forEach((locale) => {
      result[`title_${locale}`] = popup.title[locale] || '';
    });
  }
  if (popup?.content) {
    supportedLocales.forEach((locale) => {
      result[`content_${locale}`] = popup.content[locale] || '';
    });
  }
  result.image = popup?.image || {};
  result.start_at = popup?.start_at || '';
  result.stop_at = popup?.stop_at || '';
  result.platform = popup?.platform || 'all';
  return result;
}
