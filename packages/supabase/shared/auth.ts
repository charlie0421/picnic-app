// lib/auth.ts

import { getSupabaseClient } from './database.ts';

export async function validateAuth(req: Request): Promise<string> {
  const authHeader = req.headers.get('Authorization');

  if (!authHeader) {
    throw new Error('No authorization header');
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    throw new Error('Invalid authorization header format');
  }

  const supabase = getSupabaseClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);

  if (error || !user) {
    throw new Error('Invalid token');
  }

  return user.id;
}

export async function validateRole(
  userId: string,
  requiredRole: string,
): Promise<boolean> {
  const supabase = getSupabaseClient();
  const { data: userRoles, error } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', userId)
    .single();

  if (error || !userRoles) {
    return false;
  }

  return userRoles.role === requiredRole;
}
