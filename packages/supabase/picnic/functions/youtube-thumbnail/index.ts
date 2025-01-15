import {serve} from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
    const url = new URL(req.url);
    const videoId = url.searchParams.get('videoId');

    if (!videoId) {
        return new Response('Video ID is required', {status: 400});
    }

    try {
        const imageUrl = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;
        const response = await fetch(imageUrl);
        const imageData = await response.arrayBuffer();

        return new Response(imageData, {
            headers: {
                'Content-Type': 'image/jpeg',
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'public, max-age=86400',  // 24시간 캐싱
            },
        });
    } catch (error) {
        return new Response('Failed to fetch image', {status: 500});
    }
});
