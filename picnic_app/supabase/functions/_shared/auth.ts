// lib/auth.ts
import { getSupabaseClient } from './database.ts';
export async function validateAuth(req) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('No authorization header');
  }
  const token = authHeader.split(' ')[1];
  if (!token) {
    throw new Error('Invalid authorization header format');
  }
  const supabase = getSupabaseClient();
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) {
    throw new Error('Invalid token');
  }
  return user.id;
}
export async function validateRole(userId, requiredRole) {
  const supabase = getSupabaseClient();
  const { data: userRoles, error } = await supabase.from('user_roles').select('role').eq('user_id', userId).single();
  if (error || !userRoles) {
    return false;
  }
  return userRoles.role === requiredRole;
}
export function generateJWT(payload, expiresIn = '1h') {
  const key = Deno.env.get('JWT_SECRET');
  if (!key) throw new Error('JWT_SECRET is not configured');
  // JWT 생성 로직 구현
  // Deno에서 사용 가능한 JWT 라이브러리 사용
  return 'generated-jwt';
}
