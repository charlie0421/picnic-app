import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

console.log("JMA Voting function loaded")

interface VotingRequest {
  vote_id: number
  vote_item_id: number
  amount: number
  user_id: string
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { vote_id, vote_item_id, amount, user_id }: VotingRequest = await req.json()

    // 입력 검증
    if (!vote_id || !vote_item_id || !amount || !user_id) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: vote_id, vote_item_id, amount, user_id' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 오늘 일자 범위 계산
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)

    // 오늘 투표 횟수 확인
    const { data: todayVotes, error: voteCountError } = await supabaseClient
      .from('jma_voting_logs')
      .select('id')
      .eq('user_id', user_id)
      .gte('created_at', today.toISOString())
      .lt('created_at', tomorrow.toISOString())

    if (voteCountError) {
      console.error('Error checking daily votes:', voteCountError)
      return new Response(
        JSON.stringify({ error: 'Failed to check daily vote count' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 일일 5개 제한 확인
    const MAX_DAILY_VOTES = 5
    if (todayVotes && todayVotes.length >= MAX_DAILY_VOTES) {
      return new Response(
        JSON.stringify({ 
          error: 'Daily vote limit exceeded',
          message: `하루 최대 ${MAX_DAILY_VOTES}번까지 투표할 수 있습니다.`,
          current_count: todayVotes.length,
          max_count: MAX_DAILY_VOTES
        }),
        { 
          status: 429, // Too Many Requests
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 사용자 JMA 캔디 확인
    const { data: userProfile, error: userError } = await supabaseClient
      .from('profiles')
      .select('jma_candy')
      .eq('id', user_id)
      .single()

    if (userError || !userProfile) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // JMA 캔디 부족 확인
    if (userProfile.jma_candy < amount) {
      return new Response(
        JSON.stringify({ 
          error: 'Insufficient JMA candy',
          required: amount,
          available: userProfile.jma_candy
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 트랜잭션으로 투표 처리
    const { data: voteResult, error: voteError } = await supabaseClient.rpc(
      'process_jma_vote',
      {
        p_vote_id: vote_id,
        p_vote_item_id: vote_item_id,
        p_amount: amount,
        p_user_id: user_id
      }
    )

    if (voteError) {
      console.error('Vote processing error:', voteError)
      return new Response(
        JSON.stringify({ error: 'Failed to process vote' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 투표 로그 기록
    const { error: logError } = await supabaseClient
      .from('jma_voting_logs')
      .insert({
        user_id: user_id,
        vote_id: vote_id,
        vote_item_id: vote_item_id,
        amount: amount,
        created_at: new Date().toISOString()
      })

    if (logError) {
      console.error('Failed to log vote:', logError)
      // 로그 실패는 투표를 취소하지 않음 (이미 완료됨)
    }

    return new Response(
      JSON.stringify({
        success: true,
        votePickId: voteResult,
        message: 'Vote processed successfully',
        remaining_votes_today: MAX_DAILY_VOTES - (todayVotes?.length || 0) - 1
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('JMA Voting error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}) 