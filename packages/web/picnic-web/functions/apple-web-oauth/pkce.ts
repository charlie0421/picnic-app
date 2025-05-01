/**
 * PKCE (Proof Key for Code Exchange) 생성 유틸리티
 */

/**
 * 랜덤 문자열 생성
 */
function generateRandomString(length: number): string {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
    .slice(0, length);
}

/**
 * Base64URL 인코딩
 */
function base64URLEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * Uint8Array를 문자열로 변환
 */
function uint8ArrayToString(array: Uint8Array): string {
  return Array.from(array).map(byte => String.fromCharCode(byte)).join('');
}

/**
 * SHA-256 해시 생성
 */
async function sha256(plain: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(plain);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return base64URLEncode(uint8ArrayToString(new Uint8Array(hash)));
}

/**
 * PKCE 코드 챌린지와 검증자 생성
 */
export async function generatePKCE() {
  const codeVerifier = generateRandomString(64);
  const codeChallenge = await sha256(codeVerifier);
  
  return {
    codeVerifier,
    codeChallenge
  };
} 