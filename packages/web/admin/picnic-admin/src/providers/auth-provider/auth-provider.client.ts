'use client';

import type { AuthProvider } from '@refinedev/core';
import { supabaseBrowserClient } from '@utils/supabase/client';

export const authProviderClient: AuthProvider = {
  login: async ({ email, password }) => {
    const { data, error } = await supabaseBrowserClient.auth.signInWithPassword(
      {
        email,
        password,
      },
    );

    if (error) {
      return {
        success: false,
        error,
      };
    }

    if (data?.session) {
      await supabaseBrowserClient.auth.setSession(data.session);

      return {
        success: true,
        redirectTo: '/',
      };
    }

    // for third-party login
    return {
      success: false,
      error: {
        name: 'LoginError',
        message: 'Invalid username or password',
      },
    };
  },
  logout: async () => {
    const { error } = await supabaseBrowserClient.auth.signOut();

    if (error) {
      return {
        success: false,
        error,
      };
    }

    return {
      success: true,
      redirectTo: '/login',
    };
  },
  check: async () => {
    const { data, error } = await supabaseBrowserClient.auth.getUser();
    const { user } = data;

    if (error) {
      return {
        authenticated: false,
        redirectTo: '/login',
        logout: true,
      };
    }

    if (user) {
      return {
        authenticated: true,
      };
    }

    return {
      authenticated: false,
      redirectTo: '/login',
    };
  },
  getPermissions: async () => {
    const { data: { user } } = await supabaseBrowserClient.auth.getUser();
    
    if (!user) return null;

    // 사용자의 역할과 권한을 가져옵니다
    const { data: userRoles } = await supabaseBrowserClient
      .from('user_roles')
      .select('role_id')
      .eq('user_id', user.id);

    if (!userRoles?.length) return null;

    const roleIds = userRoles.map(ur => ur.role_id);
    
    const { data: permissions } = await supabaseBrowserClient
      .from('role_permissions')
      .select('permissions!inner(*)')
      .in('role_id', roleIds);

    if (!permissions?.length) return null;

    // 권한을 { resource: [actions] } 형태로 변환
    return permissions.reduce((acc: Record<string, string[]>, curr: any) => {
      const { resource, action } = curr.permissions;
      if (!acc[resource]) {
        acc[resource] = [];
      }
      if (!acc[resource].includes(action)) {
        acc[resource].push(action);
      }
      return acc;
    }, {});
  },
  getIdentity: async () => {
    const { data } = await supabaseBrowserClient.auth.getUser();

    if (data?.user) {
      return {
        ...data.user,
        name: data.user.email,
      };
    }

    return null;
  },
  onError: async (error) => {
    if (error?.code === 'PGRST301' || error?.code === 401) {
      return {
        logout: true,
      };
    }

    return { error };
  },
};
