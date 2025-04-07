export interface AdminRole {
  id: string; // UUID 타입은 문자열로 표현
  name: string;
  description: string;
  created_at: string;
  updated_at: string;
}

export interface AdminPermission {
  id: string;
  resource: string; // 리소스 이름 (예: 'artists', 'media', 'votes')
  action: string; // 액션 타입 (예: 'create', 'read', 'update', 'delete')
  description: string;
  created_at: string;
  updated_at: string;
}

export interface AdminRolePermission {
  id: string;
  role_id: string;
  permission_id: string;
  created_at: string;
  updated_at: string;
  role?: AdminRole;
  permission?: AdminPermission;
}

export interface AdminUserRole {
  id: string;
  role_id: string;
  user_id: string;
  created_at: string;
  updated_at: string;
  role?: AdminRole;
}
