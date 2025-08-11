// lib/utils.ts
export function logError(error, context) {
  console.error('Error:', {
    message: error.message,
    stack: error.stack,
    ...context
  });
}
export function cleanText(text) {
  if (!text) return '';
  return text.replace(/\s+/g, ' ').trim();
}
export function formatDate(date) {
  const d = new Date(date);
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일`;
}
export function isValidUrl(url) {
  try {
    new URL(url);
    return true;
  } catch  {
    return false;
  }
}
export function normalizeUrl(url) {
  url = url.trim();
  return url.match(/^https?:\/\//i) ? url : `https://${url}`;
}
export function sleep(ms) {
  return new Promise((resolve)=>setTimeout(resolve, ms));
}
export function retryWithBackoff(operation, maxAttempts = 3, baseDelay = 1000) {
  return new Promise((resolve, reject)=>{
    let attempts = 0;
    const attempt = async ()=>{
      try {
        const result = await operation();
        resolve(result);
      } catch (error) {
        attempts++;
        if (attempts >= maxAttempts) {
          reject(error);
          return;
        }
        const delay = baseDelay * Math.pow(2, attempts - 1);
        setTimeout(attempt, delay);
      }
    };
    attempt();
  });
}
export function sanitizeHtml(html) {
  return html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '').replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '').replace(/<[^>]*>/g, '');
}
// 숫자 포맷팅
export function formatNumber(num) {
  return new Intl.NumberFormat('ko-KR').format(num);
}
// 파일 크기 포맷팅
export function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = [
    'Bytes',
    'KB',
    'MB',
    'GB',
    'TB'
  ];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
