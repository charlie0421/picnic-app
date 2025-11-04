export const DEFAULT_TRANSLATION_LANGUAGES = [
  'ko',
  'en',
  'ja',
  'zh',
  'zh-CN',
  'zh-TW',
  'fil',
  'id',
  'th',
  'vi',
  'es',
  'bn'
];

export function parseTranslationLanguages(): string[] {
  const value = Deno.env.get('TRANSLATION_LANGUAGES');
  if (!value || !value.trim()) return DEFAULT_TRANSLATION_LANGUAGES;
  return value
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
}


