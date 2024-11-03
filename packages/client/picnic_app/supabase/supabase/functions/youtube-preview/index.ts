import {serve} from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Max-Age': '3600'
};

interface YouTubeInfo {
    videoId: string;
    title: string;
    description: string;
    thumbnailUrl: string;
    channelId: string;
    channelTitle: string;
    channelThumbnail: string;
    viewCount: number;
    publishedAt: string;
}

// HTML 엔티티 매핑
const HTML_ENTITIES: { [key: string]: string } = {
    '&quot;': '"',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&#34;': '"',
    '&#38;': '&',
    '&#39;': "'",
    '&#60;': '<',
    '&#62;': '>'
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

function cleanText(text: string | null | undefined): string {
    if (!text) return '';

    // HTML 엔티티 디코딩
    text = decodeHtmlEntities(text);

    // 연속된 공백 제거 및 트림
    text = text.replace(/\s+/g, ' ').trim();

    return text;
}

function extractVideoId(url: string): string | null {
    try {
        const urlObj = new URL(url);

        if (urlObj.hostname === 'youtu.be') {
            return urlObj.pathname.slice(1);
        }

        if (urlObj.hostname.includes('youtube.com')) {
            if (urlObj.pathname.includes('watch')) {
                return urlObj.searchParams.get('v');
            }
            if (urlObj.pathname.includes('embed') || urlObj.pathname.includes('shorts')) {
                const segments = urlObj.pathname.split('/');
                return segments[segments.length - 1] || null;
            }
        }

        return null;
    } catch {
        return null;
    }
}

async function fetchYoutubeData(videoId: string): Promise<YouTubeInfo> {
    const YOUTUBE_API_KEY = Deno.env.get('YOUTUBE_API_KEY');

    if (!YOUTUBE_API_KEY) {
        console.error('YouTube API key is not configured');
        return _createFallbackInfo(videoId);
    }

    try {
        console.log('Fetching video data for ID:', videoId);

        const videoResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/videos?` +
            `part=snippet,statistics&id=${videoId}&key=${YOUTUBE_API_KEY}`
        );

        if (!videoResponse.ok) {
            throw new Error(`Failed to fetch video data: ${videoResponse.status}`);
        }

        const videoData = await videoResponse.json();

        if (!videoData.items?.[0]) {
            throw new Error('Video not found');
        }

        const video = videoData.items[0];
        const snippet = video.snippet;
        const statistics = video.statistics;

        // 채널 정보 가져오기
        const channelResponse = await fetch(
            `https://www.googleapis.com/youtube/v3/channels?` +
            `part=snippet&id=${snippet.channelId}&key=${YOUTUBE_API_KEY}`
        );

        const channelData = await channelResponse.json();
        const channelThumbnail = channelData.items?.[0]?.snippet?.thumbnails?.default?.url || '';

        return {
            videoId,
            title: decodeHtmlEntities(snippet.title),
            description: decodeHtmlEntities(snippet.description),
            // thumbnail URLs from API response
            thumbnails: snippet.thumbnails,
            channelId: snippet.channelId,
            channelTitle: decodeHtmlEntities(snippet.channelTitle),
            channelThumbnail,
            viewCount: parseInt(statistics.viewCount || '0'),
            publishedAt: snippet.publishedAt
        };

    } catch (error) {
        console.error('Error fetching YouTube data:', error);
        return _createFallbackInfo(videoId);
    }
}

function _createFallbackInfo(videoId: string) {
    return {
        videoId,
        title: 'YouTube Video',
        description: '',
        thumbnails: {
            default: {
                url: `https://img.youtube.com/vi/${videoId}/default.jpg`,
                width: 120,
                height: 90
            },
            medium: {
                url: `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`,
                width: 320,
                height: 180
            }
        },
        channelId: '',
        channelTitle: 'Unknown Channel',
        channelThumbnail: '',
        viewCount: 0,
        publishedAt: new Date().toISOString(),
    };
}


serve(async (req) => {
    // CORS preflight 요청 처리
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
        const {url} = body;

        if (!url) {
            throw new Error('URL is required');
        }

        const videoId = extractVideoId(url);
        if (!videoId) {
            throw new Error('Invalid YouTube URL');
        }

        console.log('Processing YouTube URL:', url);
        console.log('Extracted video ID:', videoId);

        const info = await fetchYoutubeData(videoId);

        return new Response(JSON.stringify(info), {
            status: 200,
            headers: corsHeaders
        });

    } catch (error) {
        console.error('Error processing request:', error);

        let videoId = '';
        try {
            videoId = extractVideoId(url) || '';
        } catch (e) {
            console.error('Error extracting video ID for fallback:', e);
        }

        const errorResponse = {
            error: error.message,
            fallback: {
                videoId,
                title: cleanText('YouTube Video'),
                description: '',
                thumbnailUrl: videoId
                    ? `https://img.youtube.com/vi/${videoId}/0.jpg`
                    : '',
                channelId: '',
                channelTitle: cleanText('Unknown Channel'),
                channelThumbnail: '',
                viewCount: 0,
                publishedAt: new Date().toISOString(),
            }
        };

        return new Response(
            JSON.stringify(errorResponse),
            {
                status: 200,
                headers: corsHeaders
            }
        );
    }
});
