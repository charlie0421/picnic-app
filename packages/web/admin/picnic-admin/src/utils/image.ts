export const getImageUrl = (path: string): string => {
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL;

  if (!path) {
    console.warn('이미지 경로가 비어 있습니다');
    return '';
  }

  // path가 이미 전체 URL인 경우
  if (path.startsWith('http')) {
    console.log('이미지 URL 사용:', path);
    return path;
  }

  if (!cdnUrl) {
    console.warn('NEXT_PUBLIC_CDN_URL이 정의되지 않았습니다');
    return path;
  }

  const fullUrl = `${cdnUrl}/${path}`;
  console.log('생성된 이미지 URL:', fullUrl);
  return fullUrl;
};
