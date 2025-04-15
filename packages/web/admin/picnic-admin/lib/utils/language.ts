/**
 * 주어진 로케일 코드에 대한 한글 언어명을 반환합니다.
 * @param locale - 언어 코드 (ko, en, ja, zh)
 * @returns 한글로 된 언어명
 */
export const getLanguageLabel = (locale: string): string => {
  switch (locale) {
    case 'ko':
      return '한국어';
    case 'en':
      return '영어';
    case 'ja':
      return '일본어';
    case 'zh':
      return '중국어';
    default:
      return locale;
  }
};
