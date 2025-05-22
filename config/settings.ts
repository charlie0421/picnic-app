export const SUPPORTED_LANGUAGES = ['en', 'ko', 'zh', 'ja', 'id'] as const;
export const DEFAULT_LANGUAGE = 'en';

export type Language = typeof SUPPORTED_LANGUAGES[number];

export const settings = {
  languages: {
    supported: SUPPORTED_LANGUAGES,
    default: DEFAULT_LANGUAGE as Language,
  },
  layout: {
    profileImage: {
      sizes: {
        sm: 'w-8 h-8',
        md: 'w-12 h-12',
        lg: 'w-16 h-16',
      },
    },
  },
} as const;

export type Settings = typeof settings; 