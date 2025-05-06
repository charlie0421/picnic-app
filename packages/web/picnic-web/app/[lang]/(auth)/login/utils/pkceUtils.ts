// PKCE 인증 유틸리티 함수들

/**
 * 무작위 문자열을 생성합니다.
 * @param length 생성할 문자열의 길이
 * @returns 무작위 문자열
 */
export function generateRandomString(length: number): string {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, (byte) => ('0' + (byte & 0xFF).toString(16)).slice(-2)).join('');
}

/**
 * base64url 인코딩을 수행합니다.
 * @param buffer 인코딩할 ArrayBuffer
 * @returns base64url 인코딩된 문자열
 */
export function base64urlEncode(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * 문자열을 SHA-256 해시로 변환합니다.
 * @param plain 해시할 문자열
 * @returns SHA-256 해시된 ArrayBuffer
 */
export async function sha256(plain: string): Promise<ArrayBuffer> {
  const encoder = new TextEncoder();
  const data = encoder.encode(plain);
  return await crypto.subtle.digest('SHA-256', data);
}

/**
 * PKCE 코드 검증자를 생성합니다.
 * @returns 코드 검증자 문자열
 */
export function generateCodeVerifier(): string {
  // 최소 43자, 최대 128자의 문자열을 생성
  return generateRandomString(64);
}

/**
 * 코드 검증자로부터 코드 챌린지를 생성합니다.
 * @param codeVerifier 코드 검증자
 * @returns 코드 챌린지 문자열
 */
export async function generateCodeChallenge(codeVerifier: string): Promise<string> {
  const hashed = await sha256(codeVerifier);
  return base64urlEncode(hashed);
}

/**
 * PKCE 값을 안전하게 저장합니다.
 * @param codeVerifier 저장할 코드 검증자
 */
export function storeCodeVerifier(codeVerifier: string): void {
  try {
    localStorage.setItem('pkce_code_verifier', codeVerifier);
    localStorage.setItem('pkce_timestamp', Date.now().toString());
  } catch (e) {
    console.error('코드 검증자 저장 실패:', e);
  }
}

/**
 * 저장된 코드 검증자를 가져옵니다.
 * @returns 저장된 코드 검증자
 */
export function getStoredCodeVerifier(): string | null {
  try {
    return localStorage.getItem('pkce_code_verifier');
  } catch (e) {
    console.error('코드 검증자 불러오기 실패:', e);
    return null;
  }
}

/**
 * 코드 검증자 저장소를 정리합니다.
 */
export function clearCodeVerifier(): void {
  try {
    localStorage.removeItem('pkce_code_verifier');
    localStorage.removeItem('pkce_timestamp');
  } catch (e) {
    console.error('코드 검증자 정리 실패:', e);
  }
} 