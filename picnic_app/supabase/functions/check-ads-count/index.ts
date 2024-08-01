import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { decode } from 'https://deno.land/x/djwt@v2.8/mod.ts'

const HOURLY_LIMIT = parseInt(Deno.env.get('HOURLY_LIMIT') || '5', 10)
const DAILY_LIMIT = parseInt(Deno.env.get('DAILY_LIMIT') || '20', 10)

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'No authorization header' }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    })
  }

  const token = authHeader.split(' ')[1]
  const [_header, payload] = decode(token)
  const user_id = payload.sub

  if (!user_id) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    })
  }

  const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
  )

  const hourAgo = new Date(Date.now() - 60 * 60 * 1000)
  const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000)

  const { data, error } = await supabase
      .from('transaction_admob')
      .select('created_at')
      .eq('user_id', user_id)
      .gte('created_at', dayAgo.toISOString())

  if (error) {
    return new Response(JSON.stringify({ error: 'Error fetching ad view count' }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    })
  }

  const hourlyData = data.filter(row => new Date(row.created_at) >= hourAgo)
  const hourlyCount = hourlyData.length
  const dailyCount = data.length

  const isLimitExceeded = hourlyCount >= HOURLY_LIMIT || dailyCount >= DAILY_LIMIT

  console.log(`User ${user_id} has viewed ${hourlyCount} ads in the last hour and ${dailyCount} ads in the last 24 hours`)

  let nextAvailableTime = new Date()
  if (isLimitExceeded) {
    if (hourlyCount >= HOURLY_LIMIT) {
      // Find the oldest view within the last hour
      const oldestHourlyView = new Date(Math.min(...hourlyData.map(row => new Date(row.created_at).getTime())))
      nextAvailableTime = new Date(oldestHourlyView.getTime() + 60 * 60 * 1000)
    }
    if (dailyCount >= DAILY_LIMIT) {
      // Find the oldest view within the last 24 hours
      const oldestDailyView = new Date(Math.min(...data.map(row => new Date(row.created_at).getTime())))
      const dailyNextAvailable = new Date(oldestDailyView.getTime() + 24 * 60 * 60 * 1000)
      // Use the later of the two times
      nextAvailableTime = new Date(Math.max(nextAvailableTime.getTime(), dailyNextAvailable.getTime()))
    }

    return new Response(JSON.stringify({
      allowed: false,
      message: 'Ad view limit exceeded. Please try again later.',
      nextAvailableTime: nextAvailableTime.toISOString(),
      hourlyCount,
      dailyCount,
      hourlyLimit: HOURLY_LIMIT,
      dailyLimit: DAILY_LIMIT

    }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    })
  }

  return new Response(JSON.stringify({
    allowed: true,
    message: 'Ad view allowed',
    nextAvailableTime: nextAvailableTime.toISOString(),
    hourlyCount,
    dailyCount,
    hourlyLimit: HOURLY_LIMIT,
    dailyLimit: DAILY_LIMIT

  }), {
    headers: { "Content-Type": "application/json" }
  })
})