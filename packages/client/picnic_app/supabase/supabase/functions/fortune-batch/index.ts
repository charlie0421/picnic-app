import { createErrorResponse, createSuccessResponse } from '../_shared/response.ts';
import { getSupabaseClient } from '.././_shared/index.ts';

interface Artist {
    id: number;
}

interface BatchLogEntry {
    id?: number;
    year: number;
    total_artists: number;
    processed_count: number;
    failed_count: number;
    status: 'processing' | 'completed' | 'failed';
    completed_at?: string;
}

// 기존 운세 생성 엣지 함수의 URL
const FORTUNE_EDGE_URL = 'https://api.picnic.fan/functions/v1/fortune-teller';

// Supabase 클라이언트 초기화
const supabase = getSupabaseClient();

// 단일 아티스트 운세 생성 함수
async function generateSingleFortune(artist_id: number, year: number) {
    const response = await fetch(FORTUNE_EDGE_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`,
        },
        body: JSON.stringify({ artist_id, year }),
    });

    if (!response.ok) {
        throw new Error(
            `HTTP error! status: ${response.status}, message: ${await response.text()}`,
        );
    }

    return response.json();
}

async function processBatchInBackground(artists: Artist[], year: number, batchLogId: number) {
    const batchSize = 2;
    let processedCount = 0;
    let failedCount = 0;

    try {
        for (let i = 0; i < artists.length; i += batchSize) {
            const batch = artists.slice(i, i + batchSize);

            const promises = batch.map((artist: Artist) =>
                fetch(FORTUNE_EDGE_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${Deno.env.get('SUPABASE_ANON_KEY')}`,
                    },
                    body: JSON.stringify({
                        artist_id: artist.id,
                        year: year,
                    }),
                }).then(async (res) => {
                    if (!res.ok) {
                        const errorText = await res.text();
                        throw new Error(`HTTP error! status: ${res.status}, message: ${errorText}`);
                    }
                    processedCount++;
                    return res.json();
                }).then(null, (error: Error) => {
                    console.error(`Failed to process artist ${artist.id}:`, error);
                    failedCount++;
                    return null;
                })
            );

            // 현재 배치 처리
            await Promise.all(promises);

            // 중간 진행상황 업데이트
            await supabase
                .from('fortune_batch_log')
                .update({
                    processed_count: processedCount,
                    failed_count: failedCount,
                })
                .eq('id', batchLogId);

            // Rate limiting 방지
            if (i + batchSize < artists.length) {
                await new Promise((resolve) => setTimeout(resolve, 1000));
            }
        }

        // 처리 완료 상태 업데이트
        await supabase
            .from('fortune_batch_log')
            .update({
                processed_count: processedCount,
                failed_count: failedCount,
                status: 'completed',
                completed_at: new Date().toISOString(),
            })
            .eq('id', batchLogId);
    } catch (error) {
        console.error('Background processing error:', error);

        // 에러 상태 업데이트
        await supabase
            .from('fortune_batch_log')
            .update({
                status: 'failed',
                failed_count: artists.length - processedCount,
                completed_at: new Date().toISOString(),
            })
            .eq('id', batchLogId);
    }
}

Deno.serve(async (req) => {
    try {
        const { year, artist_id } = await req.json();

        if (!year || year < 2000 || year > 2100) {
            return createErrorResponse(
                '2000년에서 2100년 사이의 연도를 입력해주세요.',
                400,
                'INVALID_YEAR',
            );
        }

        // 단일 아티스트 처리
        if (artist_id) {
            try {
                const result = await generateSingleFortune(artist_id, year);
                return createSuccessResponse({
                    message: `${year}년 아티스트 ID ${artist_id}의 운세가 생성되었습니다.`,
                    fortune: result,
                });
            } catch (error) {
                console.error(`Single fortune generation error for artist ${artist_id}:`, error);
                return createErrorResponse(
                    `아티스트 ID ${artist_id}의 운세 생성 중 오류가 발생했습니다.`,
                    500,
                    'SINGLE_FORTUNE_ERROR',
                    { shouldRetry: true },
                );
            }
        }

        // 활성 아티스트 조회
        const { data: artists, error: queryError } = await supabase
            .from('artist')
            .select('id')
            .is('deleted_at', null)
            .order('id');

        if (queryError) {
            throw new Error(`Failed to fetch artists: ${queryError.message}`);
        }

        if (!artists || artists.length === 0) {
            return createErrorResponse(
                '처리할 아티스트가 없습니다.',
                404,
                'NO_ARTISTS_FOUND',
            );
        }

        // 배치 로그 생성
        const { data: batchLog, error: insertError } = await supabase
            .from('fortune_batch_log')
            .insert({
                year: year,
                total_artists: artists.length,
                processed_count: 0,
                failed_count: 0,
                status: 'processing',
            })
            .select()
            .single();

        if (insertError || !batchLog) {
            throw new Error(`Failed to create batch log: ${insertError?.message}`);
        }

        // 백그라운드 처리 시작
        processBatchInBackground(artists, year, batchLog.id)
            .then(() => console.log('Background processing completed'))
            .catch((error) => console.error('Background processing failed:', error));

        return createSuccessResponse({
            message: `${year}년 운세 생성이 시작되었습니다. batch_id: ${batchLog.id}`,
            batch_id: batchLog.id,
            total_artists: artists.length,
        });
    } catch (error) {
        console.error('Fortune processing error:', error);

        return createErrorResponse(
            '운세 생성 중 오류가 발생했습니다.',
            500,
            'FORTUNE_ERROR',
            { shouldRetry: true },
        );
    }
});
