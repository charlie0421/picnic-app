export const getImageUrl = (path: string): string => {
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL;

  if (!path) {
    console.warn('이미지 경로가 비어 있습니다');
    return '';
  }

  // path가 이미 전체 URL인 경우
  if (path.startsWith('http')) {
    return path;
  }

  if (!cdnUrl) {
    console.warn('NEXT_PUBLIC_CDN_URL이 정의되지 않았습니다');
    return path;
  }

  const fullUrl = `${cdnUrl}/${path}`;
  return fullUrl;
};
