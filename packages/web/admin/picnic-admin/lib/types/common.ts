export interface MultilingualText {
  ko: string;
  en: string;
  ja: string;
  zh: string;
  id: string;
  [key: string]: string; // 추가 언어를 위한 인덱스 시그니처
}
