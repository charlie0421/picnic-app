/**
 * 프로젝트 전체에서 사용할 색상 테마 정의
 */

export const COLORS = {
  primary: '#9374FF',
  secondary: '#83FBC8',
  sub: '#CDFB5D',
  point: '#FFA9BD',
  point_900: '#EB4A71',
};

// Ant Design 테마 설정용 색상 객체
export const getThemeColors = () => {
  return {
    colorPrimary: COLORS.primary,
    colorSuccess: COLORS.secondary,
    colorInfo: COLORS.sub,
    colorWarning: COLORS.point,
    colorError: COLORS.point_900,
  };
};
