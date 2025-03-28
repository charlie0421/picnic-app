export function base64UrlToBase64(base64Url: string): string {
  return base64Url
    .replace(/-/g, '+')
    .replace(/_/g, '/')
    .padEnd(base64Url.length + ((4 - (base64Url.length % 4)) % 4), '=');
}

export function safeAtob(base64: string): Uint8Array {
  try {
    return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  } catch (e) {
    console.error('Failed to decode Base64:', base64);
    throw new Error('Invalid Base64 string');
  }
}
