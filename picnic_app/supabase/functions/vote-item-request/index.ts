import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface VoteItemRequestData {
  vote_id: number;
  title: string;
  description?: string;
  artist_name: string;
  artist_group?: string;
  reason?: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

Deno.serve(async (req) => {
  // CORS 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      global: {
        headers: { Authorization: req.headers.get('Authorization') ?? '' }
      }
    }
  );

  try {
    const method = req.method;
    const url = new URL(req.url);
    const pathSegments = url.pathname.split('/').filter(Boolean);

    switch (method) {
      case 'POST':
        return await handleCreateRequest(req, supabaseClient);
      case 'GET':
        if (pathSegments.length >= 3 && pathSegments[2] === 'vote') {
          const voteId = parseInt(pathSegments[3]);
          return await handleGetRequestsByVote(voteId, supabaseClient);
        } else if (pathSegments.length >= 3 && pathSegments[2] === 'user') {
          const userId = pathSegments[3];
          return await handleGetRequestsByUser(userId, supabaseClient);
        } else if (pathSegments.length >= 3) {
          const requestId = pathSegments[2];
          return await handleGetRequest(requestId, supabaseClient);
        } else {
          return await handleGetAllRequests(supabaseClient);
        }
      case 'PUT':
        if (pathSegments.length >= 3) {
          const requestId = pathSegments[2];
          return await handleUpdateRequest(req, requestId, supabaseClient);
        }
        break;
      case 'DELETE':
        if (pathSegments.length >= 3) {
          const requestId = pathSegments[2];
          return await handleDeleteRequest(requestId, supabaseClient);
        }
        break;
      default:
        return new Response(
          JSON.stringify({ error: 'Method not allowed' }),
          { 
            status: 405, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        );
    }

    return new Response(
      JSON.stringify({ error: 'Invalid endpoint' }),
      { 
        status: 404, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

// 새 투표 아이템 신청 생성
async function handleCreateRequest(
  req: Request, 
  supabaseClient: any
): Promise<Response> {
  try {
    const requestData: VoteItemRequestData = await req.json();
    
    // 필수 필드 검증
    if (!requestData.vote_id || !requestData.title || !requestData.artist_name) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required fields: vote_id, title, artist_name' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // 현재 사용자 정보 가져오기
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Authentication required' 
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // 투표가 존재하는지 확인
    const { data: vote, error: voteError } = await supabaseClient
      .from('vote')
      .select('id, vote_title, start_at, stop_at')
      .eq('id', requestData.vote_id)
      .single();

    if (voteError || !vote) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Vote not found' 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // 신청 생성
    const { data: voteItemRequest, error: requestError } = await supabaseClient
      .from('vote_item_requests')
      .insert({
        vote_id: requestData.vote_id,
        title: requestData.title,
        description: requestData.description,
        status: 'pending'
      })
      .select()
      .single();

    if (requestError) {
      console.error('Error creating vote item request:', requestError);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to create vote item request' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // 사용자 신청 정보 생성
    const { data: userRequest, error: userRequestError } = await supabaseClient
      .from('vote_item_request_users')
      .insert({
        vote_item_request_id: voteItemRequest.id,
        user_id: user.id,
        artist_name: requestData.artist_name,
        artist_group: requestData.artist_group,
        reason: requestData.reason,
        status: 'pending'
      })
      .select()
      .single();

    if (userRequestError) {
      console.error('Error creating user request:', userRequestError);
      
      // 롤백: 생성된 vote_item_request 삭제
      await supabaseClient
        .from('vote_item_requests')
        .delete()
        .eq('id', voteItemRequest.id);

      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to create user request' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: {
          vote_item_request: voteItemRequest,
          user_request: userRequest
        }
      }),
      { 
        status: 201, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleCreateRequest:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Invalid request data' 
      }),
      { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 특정 투표의 모든 신청 조회
async function handleGetRequestsByVote(
  voteId: number, 
  supabaseClient: any
): Promise<Response> {
  try {
    const { data: requests, error } = await supabaseClient
      .from('vote_item_requests')
      .select(`
        *,
        vote_item_request_users (
          id,
          user_id,
          artist_name,
          artist_group,
          reason,
          status,
          created_at
        )
      `)
      .eq('vote_id', voteId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching requests by vote:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to fetch requests' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: requests 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleGetRequestsByVote:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 특정 사용자의 모든 신청 조회
async function handleGetRequestsByUser(
  userId: string, 
  supabaseClient: any
): Promise<Response> {
  try {
    const { data: userRequests, error } = await supabaseClient
      .from('vote_item_request_users')
      .select(`
        *,
        vote_item_requests (
          id,
          vote_id,
          title,
          description,
          status,
          created_at,
          vote (
            id,
            vote_title,
            start_at,
            stop_at
          )
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching requests by user:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to fetch user requests' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: userRequests 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleGetRequestsByUser:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 특정 신청 조회
async function handleGetRequest(
  requestId: string, 
  supabaseClient: any
): Promise<Response> {
  try {
    const { data: request, error } = await supabaseClient
      .from('vote_item_requests')
      .select(`
        *,
        vote_item_request_users (
          id,
          user_id,
          artist_name,
          artist_group,
          reason,
          status,
          created_at
        ),
        vote (
          id,
          vote_title,
          start_at,
          stop_at
        )
      `)
      .eq('id', requestId)
      .single();

    if (error) {
      console.error('Error fetching request:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Request not found' 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: request 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleGetRequest:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 모든 승인된 신청 조회
async function handleGetAllRequests(supabaseClient: any): Promise<Response> {
  try {
    const { data: requests, error } = await supabaseClient
      .from('vote_item_requests')
      .select(`
        *,
        vote_item_request_users (
          id,
          artist_name,
          artist_group,
          status,
          created_at
        ),
        vote (
          id,
          vote_title,
          start_at,
          stop_at
        )
      `)
      .eq('status', 'approved')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching all requests:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to fetch requests' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: requests 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleGetAllRequests:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 신청 상태 업데이트 (관리자용)
async function handleUpdateRequest(
  req: Request,
  requestId: string, 
  supabaseClient: any
): Promise<Response> {
  try {
    const updateData = await req.json();
    
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Authentication required' 
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    const { data: updatedRequest, error } = await supabaseClient
      .from('vote_item_requests')
      .update(updateData)
      .eq('id', requestId)
      .select()
      .single();

    if (error) {
      console.error('Error updating request:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to update request' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: updatedRequest 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleUpdateRequest:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Invalid request data' 
      }),
      { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
}

// 신청 삭제
async function handleDeleteRequest(
  requestId: string, 
  supabaseClient: any
): Promise<Response> {
  try {
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Authentication required' 
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    const { error } = await supabaseClient
      .from('vote_item_requests')
      .delete()
      .eq('id', requestId);

    if (error) {
      console.error('Error deleting request:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to delete request' 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Request deleted successfully' 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Error in handleDeleteRequest:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
} 