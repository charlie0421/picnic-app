export const getImageUrl = (path: string) => {
  const cdnUrl = process.env.NEXT_PUBLIC_SUPABASE_CDN_URL;
  if (!cdnUrl) {
    console.warn('NEXT_PUBLIC_SUPABASE_CDN_URL is not defined');
    return path;
  }
  return `${cdnUrl}/${path}`;
};
