// lib/utils.ts

import { ErrorContext } from './types.ts';

export function logError(error: Error, context?: ErrorContext): void {
  console.error('Error:', {
    message: error.message,
    stack: error.stack,
    ...context
  });
}

export function cleanText(text: string | null | undefined): string {
  if (!text) return '';
  
  return text
    .replace(/\s+/g, ' ')
    .trim();
}

export function formatDate(date: Date | string): string {
  const d = new Date(date);
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일`;
}

export function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

export function normalizeUrl(url: string): string {
  url = url.trim();
  return url.match(/^https?:\/\//i) ? url : `https://${url}`;
}

export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxAttempts = 3,
  baseDelay = 1000
): Promise<T> {
  return new Promise((resolve, reject) => {
    let attempts = 0;

    const attempt = async () => {
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

export function sanitizeHtml(html: string): string {
  return html
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<[^>]*>/g, '');
}

// 숫자 포맷팅
export function formatNumber(num: number): string {
  return new Intl.NumberFormat('ko-KR').format(num);
}

// 파일 크기 포맷팅
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
