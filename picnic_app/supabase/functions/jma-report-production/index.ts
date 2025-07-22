import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const PRODUCTION_DOMAIN = 'https://lite-be.cfanfever.com'
const AUTH_ENDPOINT = '/api/v1/access_token'
const VOTE_REPORT_ENDPOINT = '/api/v1/vote-report/picnic'

// Production API 키 정보 (하드코딩)
const API_KEY = 'v6723ab0-83b2-31eb-43ac-345ee0e2a4hk'
const API_SECRET = 'L34YOVLvkRPOjJW5vM5tc33jF1LAbMSOFt7dEHKG'

/**
 * HmacSHA256 시그니처를 생성합니다.
 */
async function createSignature(apiKey: string, randomStr: string, accessTime: string, apiSecret: string): Promise<string> {
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(apiSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  const data = `${btoa(randomStr)}.${btoa(accessTime)}.${btoa(apiKey)}`
  const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(data))

  // ArrayBuffer를 16진수 문자열로 변환
  return Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

/**
 * 외부 API에서 access_token을 가져옵니다.
 */
async function getAccessToken(): Promise<string> {
  const url = `${PRODUCTION_DOMAIN}${AUTH_ENDPOINT}`
  console.log(`Fetching access token from: ${url}`)
  
  const randomStr = crypto.randomUUID().replaceAll('-', '') // 32자리 랜덤 문자열
  const accessTime = Math.floor(Date.now() / 1000).toString() // 10자리 타임스탬프

  const signature = await createSignature(API_KEY, randomStr, accessTime, API_SECRET)

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      api_key: API_KEY,
      random_str: randomStr,
      access_time: accessTime,
      signature: signature,
    }),
  })

  if (!response.ok) {
    const errorBody = await response.text()
    console.error('Failed to get access token:', errorBody)
    throw new Error(`Authentication failed with status: ${response.status}`)
  }

  const { data } = await response.json()
  if (!data || !data.access_token) {
    throw new Error('Access token not found in response')
  }
  
  console.log('Successfully fetched access token.')
  return data.access_token
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const accessToken = await getAccessToken()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // RLS를 우회하기 위해 service_role_key 사용
    )

    // 현재 진행 중인 투표와 관련된 모든 vote_item 정보를 가져옵니다.
    const now = new Date().toISOString()
    const { data: voteItems, error: dbError } = await supabaseClient
      .from('vote_item')
      .select(`
        vote_total,
        artist (
          partner_data
        ),
        vote!inner (
          id,
          vote_sub_category,
          is_partnership,
          partner
        )
      `)
      .eq('vote.is_partnership', true)
      .eq('vote.partner', 'jma')
      .filter('vote.start_at', 'lte', now)
      .filter('vote.stop_at', 'gte', now)

    if (dbError) throw dbError
    if (!voteItems || voteItems.length === 0) {
      return new Response(JSON.stringify({ success: true, message: 'No active votes to report.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }
    
    console.log(`Found ${voteItems.length} active vote items to report.`)

    // API 명세에 맞는 데이터만 필터링합니다.
    const awardRegex = /^[A-Z]{2}\s\d{2}$/
    const talentNumberRegex = /^[A-Z]{2}\s\d{2}-\d{2,3}$/

    const validVoteItems = voteItems.filter(item => {
      const vote = item.vote
      const artist = item.artist
      
      const award = vote?.vote_sub_category
      const talentNumber = artist?.partner_data

      // artist, vote, partner_data, vote_sub_category 모두 존재해야 합니다.
      if (!artist || !vote || !talentNumber || !award) {
        return false
      }

      // API 형식에 맞는지 정규식으로 검증합니다.
      return awardRegex.test(award) && talentNumberRegex.test(talentNumber)
    })

    console.log(`Found ${validVoteItems.length} valid items to send after filtering.`)

    if (validVoteItems.length === 0) {
      return new Response(JSON.stringify({ success: true, message: 'No valid votes to report.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // vote.id 오름차순, 그 다음 vote_total 내림차순으로 정렬합니다.
    const sortedVoteItems = validVoteItems.sort((a, b) => {
      const voteIdA = a.vote?.id || 0;
      const voteIdB = b.vote?.id || 0;
      const voteTotalA = a.vote_total || 0;
      const voteTotalB = b.vote_total || 0;

      if (voteIdA !== voteIdB) {
        return voteIdA - voteIdB; // vote.id 오름차순
      }
      return voteTotalB - voteTotalA; // votes 내림차순
    });

    const payload = {
      data: sortedVoteItems.map(item => ({
        award: item.vote.vote_sub_category,
        talent_number: item.artist.partner_data,
        votes: item.vote_total,
      })),
    }
    
    const updateUrl = `${PRODUCTION_DOMAIN}${VOTE_REPORT_ENDPOINT}`
    console.log(`Sending vote report to: ${updateUrl}`)

    // 페이로드를 여러 줄로 나누어 로깅합니다.
    const payloadString = JSON.stringify(payload, null, 2);
    const chunkSize = 8000; // 로그 길이 제한에 걸리지 않도록 청크 크기 설정
    console.log('--- Start of Payload ---');
    for (let i = 0, chunkCounter = 1; i < payloadString.length; i += chunkSize, chunkCounter++) {
        console.log(`[Chunk ${chunkCounter}] ${payloadString.substring(i, i + chunkSize)}`);
    }
    console.log('--- End of Payload ---');

    const updateResponse = await fetch(updateUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'access-token': accessToken,
      },
      body: JSON.stringify(payload),
    })

    if (!updateResponse.ok) {
      const errorBody = await updateResponse.text()
      console.error('Failed to send vote updates:', errorBody)
      throw new Error(`API call failed with status: ${updateResponse.status}`)
    }
    
    const result = await updateResponse.json()
    console.log('Successfully sent vote updates:', result)

    return new Response(JSON.stringify({ success: true, message: 'Vote report sent successfully.', api_response: result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('An error occurred in the main handler:', error)
    if (error.cause) {
      console.error('Root cause:', error.cause);
    }
    return new Response(JSON.stringify({ error: error.message, cause: error.cause }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
