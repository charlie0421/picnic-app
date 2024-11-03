import {serve} from "https://deno.land/std@0.168.0/http/server.ts";
import {DOMParser} from "https://deno.land/x/deno_dom/deno-dom-wasm.ts";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Max-Age': '3600'
};

interface MetaData {
    title?: string;
    description?: string;
    image?: string;
    favicon?: string;
    url?: string;
}

// HTML 엔티티 매핑
const HTML_ENTITIES: { [key: string]: string } = {
    '&quot;': '"',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&copy;': '©',
    '&reg;': '®',
    '&deg;': '°',
    '&#34;': '"',
    '&#38;': '&',
    '&#39;': "'",
    '&#60;': '<',
    '&#62;': '>',
    '&#160;': ' ',
    '&#169;': '©',
    '&#174;': '®',
    '&#176;': '°',
};

function decodeHtmlEntities(text: string): string {
    if (!text) return '';

    // 숫자 엔티티 처리 (&#xxxx;)
    text = text.replace(/&#(\d+);/g, (match, dec) => {
        try {
            return String.fromCharCode(parseInt(dec, 10));
        } catch {
            return match;
        }
    });

    // 16진수 엔티티 처리 (&#xXXXX;)
    text = text.replace(/&#x([0-9a-f]+);/gi, (match, hex) => {
        try {
            return String.fromCharCode(parseInt(hex, 16));
        } catch {
            return match;
        }
    });

    // 일반 엔티티 처리
    return text.replace(/&[#A-Za-z0-9]+;/g, (entity) => {
        return HTML_ENTITIES[entity] || entity;
    });
}

function normalizeUrl(url: string): string {
    url = url.trim();
    if (!url.match(/^https?:\/\//i)) {
        return `https://${url}`;
    }
    return url;
}

function isValidUrl(url: string): boolean {
    try {
        const urlObj = new URL(normalizeUrl(url));
        return !!urlObj.host;
    } catch (e) {
        return false;
    }
}

function cleanText(text: string | null | undefined): string {
    if (!text) return '';

    // HTML 엔티티 디코딩
    text = decodeHtmlEntities(text);

    // 연속된 공백 제거 및 트림
    text = text.replace(/\s+/g, ' ').trim();

    return text;
}

async function fetchWithEncoding(url: string): Promise<string> {
    const response = await fetch(url, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7,ja;q=0.6,zh-CN;q=0.5,zh;q=0.4',
        }
    });

    const contentType = response.headers.get('content-type');
    const buffer = await response.arrayBuffer();

    let encoding = 'utf-8';
    const charsetMatch = contentType?.match(/charset=([^;]+)/i);
    if (charsetMatch) {
        encoding = charsetMatch[1];
    }

    try {
        return new TextDecoder(encoding).decode(buffer);
    } catch (e) {
        console.warn(`Failed to decode with ${encoding}, trying common encodings`);
        for (const enc of ['utf-8', 'shift-jis', 'euc-kr', 'gb2312', 'big5']) {
            try {
                return new TextDecoder(enc).decode(buffer);
            } catch {

            }
        }
        console.warn('All decodings failed, falling back to utf-8');
        return new TextDecoder('utf-8', {fatal: false}).decode(buffer);
    }
}

serve(async (req) => {
    // CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response(null, {
            status: 204,
            headers: corsHeaders
        });
    }

    try {
        if (req.method !== 'POST') {
            throw new Error('Method not allowed');
        }

        const body = await req.json();
        const requestUrl = body.url;

        if (!requestUrl) {
            throw new Error('URL is required');
        }

        if (!isValidUrl(requestUrl)) {
            throw new Error('Invalid URL format');
        }

        const normalizedUrl = normalizeUrl(requestUrl);
        console.log('Fetching URL:', normalizedUrl);

        const html = await fetchWithEncoding(normalizedUrl);
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');

        if (!doc) {
            throw new Error('Failed to parse HTML');
        }

        const metadata: MetaData = {url: normalizedUrl};

        // Meta tags to check (in order of preference)
        const metaTags = {
            title: [
                'og:title',
                'twitter:title',
                'title',
                'dc.title'
            ],
            description: [
                'og:description',
                'twitter:description',
                'description',
                'dc.description'
            ],
            image: [
                'og:image',
                'twitter:image',
                'image'
            ]
        };

        // Extract metadata
        for (const [key, tags] of Object.entries(metaTags)) {
            for (const tag of tags) {
                const content =
                    doc.querySelector(`meta[property="${tag}"]`)?.getAttribute('content') ||
                    doc.querySelector(`meta[name="${tag}"]`)?.getAttribute('content');
                if (content) {
                    metadata[key as keyof MetaData] = cleanText(content);
                    break;
                }
            }
        }

        // Fallback to title tag
        if (!metadata.title) {
            metadata.title = cleanText(doc.querySelector('title')?.textContent);
        }

        // Fallback to main content for description
        if (!metadata.description) {
            const mainContent = doc.querySelector('article, main, body')?.textContent;
            if (mainContent) {
                const cleanContent = cleanText(mainContent);
                metadata.description = cleanContent.slice(0, 200) + (cleanContent.length > 200 ? '...' : '');
            }
        }

        // Get favicon
        const faviconLink = doc.querySelector('link[rel="icon"], link[rel="shortcut icon"]');
        if (faviconLink) {
            let faviconUrl = faviconLink.getAttribute('href');
            if (faviconUrl) {
                const urlObj = new URL(normalizedUrl);
                if (faviconUrl.startsWith('//')) {
                    faviconUrl = urlObj.protocol + faviconUrl;
                } else if (faviconUrl.startsWith('/')) {
                    faviconUrl = `${urlObj.protocol}//${urlObj.host}${faviconUrl}`;
                } else if (!faviconUrl.startsWith('http')) {
                    faviconUrl = `${urlObj.protocol}//${urlObj.host}/${faviconUrl}`;
                }
                metadata.favicon = faviconUrl;
            }
        }

        // Set defaults if needed
        const urlObj = new URL(normalizedUrl);
        if (!metadata.title) {
            metadata.title = urlObj.hostname;
        }
        if (!metadata.description) {
            metadata.description = 'Click to visit the website';
        }

        // 결과 로깅
        console.log('Extracted metadata:', {
            title: metadata.title,
            description: metadata.description?.slice(0, 100) + '...',
            image: metadata.image,
            favicon: metadata.favicon
        });

        return new Response(JSON.stringify(metadata), {
            headers: corsHeaders
        });

    } catch (error) {
        console.error('Error:', error);
        const fallback = {
            error: error.message,
            fallback: {
                title: error.url ? new URL(error.url).hostname : 'Unknown website',
                description: 'Click to visit the website',
                url: error.url || 'Invalid URL'
            }
        };

        return new Response(JSON.stringify(fallback), {
            headers: corsHeaders
        });
    }
});
